/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package eu.clarin.cmd.toolkit;

import java.io.File;
import java.io.IOException;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.Source;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import javax.xml.validation.Validator;
import net.sf.saxon.s9api.DOMDestination;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.XdmAtomicValue;
import net.sf.saxon.s9api.XdmDestination;
import net.sf.saxon.s9api.XdmNode;
import net.sf.saxon.s9api.XdmValue;
import net.sf.saxon.s9api.XsltTransformer;
import nl.mpi.tla.schemanon.Message;
import nl.mpi.tla.schemanon.SaxonUtils;
import nl.mpi.tla.schemanon.SchemAnon;
import org.junit.*;

import static org.junit.Assert.*;
import org.w3c.dom.Document;

/**
 *
 * @author menwin
 */
public class TestCMDToolkit {

    XsltTransformer upgradeCMDSpec = null;
    XsltTransformer upgradeCMDRec = null;
    XsltTransformer transformCMDSpecInXSD = null;
    SchemAnon validateCMDSpec = null; 

    @Before
    public void setUp() {
        try {
            upgradeCMDSpec = SaxonUtils.buildTransformer(CMDToolkit.class.getResource("/toolkit/upgrade/cmd-component-1_1-to-1_2.xsl")).load();
            upgradeCMDRec = SaxonUtils.buildTransformer(CMDToolkit.class.getResource("/toolkit/upgrade/cmd-record-1_1-to-1_2.xsl")).load();
            transformCMDSpecInXSD = SaxonUtils.buildTransformer(CMDToolkit.class.getResource("/toolkit/xslt/comp2schema.xsl")).load();
            validateCMDSpec = new SchemAnon(CMDToolkit.class.getResource("/toolkit/xsd/cmd-component.xsd").toURI().toURL()); 
        } catch(Exception e) {
            System.err.println("!ERR: couldn't setup the testing environment!");
            System.err.println(""+e);
            e.printStackTrace(System.err);
        }
    }

    @After
    public void tearDown() {
    }
    
    protected Document transform(XsltTransformer trans,Source src) throws Exception {
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.newDocument();
            DOMDestination dest = new DOMDestination(doc);
            trans.setSource(src);
            trans.setDestination(dest);
            // always set cmd-toolkit to the current working directory, which is expected to be where pom.xml lives
            trans.setParameter(new QName("cmd-toolkit"),new XdmAtomicValue(Paths.get("").toAbsolutePath().toString()+"/src/main/resources/toolkit"));
            trans.transform();
            return doc;
        } catch (Exception e) {
            System.out.println("!ERR: failed transform: "+e);
            e.printStackTrace(System.out);
            throw e;
        }
    }
    
    protected void printMessages(SchemAnon anon) throws Exception {
        for (Message msg : anon.getMessages()) {
            System.out.println("" + (msg.isError() ? "ERROR" : "WARNING") + (msg.getLocation() != null ? " at " + msg.getLocation() : ""));
            System.out.println("  " + msg.getText());
        }
    }
    
    protected int countErrors(SchemAnon anon) throws Exception {
        int cnt = 0;
        for (Message msg : anon.getMessages())
            cnt += (msg.isError()?1:0);
        return cnt;
    }
    
    protected Document upgradeCMDSpec(String spec) throws Exception {
        System.out.println("Upgrade CMD spec["+spec+"]");
        return transform(upgradeCMDSpec,new javax.xml.transform.stream.StreamSource(new java.io.File(TestCMDToolkit.class.getResource(spec).toURI())));
    }

    protected Document upgradeCMDRecord(String rec) throws Exception {
        System.out.println("Upgrade CMD spec["+rec+"]");
        return transform(upgradeCMDRec,new javax.xml.transform.stream.StreamSource(new java.io.File(TestCMDToolkit.class.getResource(rec).toURI())));
    }
    
    protected Document transformCMDSpecInXSD(String spec,Source src) throws Exception { 
        System.out.println("Transform CMD spec["+spec+"] into XSD");
        return transform(transformCMDSpecInXSD,src);
    }
    
    protected Document transformCMDSpecInXSD(String spec) throws Exception {
        return transformCMDSpecInXSD(spec,new javax.xml.transform.stream.StreamSource(new java.io.File(TestCMDToolkit.class.getResource(spec).toURI())));
    }
    
    protected boolean validateCMDSpec(String spec,Source src) throws Exception {
        System.out.println("Validate CMD spec["+spec+"]");
        return validateCMDSpec.validate(src);
    }
    
    protected boolean validateCMDRecord(String spec,SchemAnon anon,String rec,Source src) throws Exception {
        System.out.println("Validate CMD record["+rec+"] against spec["+spec+"]");
        return anon.validate(src);
    }

    @Test
    public void valid_Adelheid() throws Exception {
        System.out.println("DBG: current working directory["+Paths.get("").toAbsolutePath().toString()+"]");
        
        String profile = "/toolkit/Adelheid/profiles/clarin.eu:cr1:p_1311927752306.xml";
        String record  = "/toolkit/Adelheid/records/Adelheid.cmdi";
        
        // upgrade the profile from 1.1 to 1.2
        Document upgradedProfile = upgradeCMDSpec(profile);
        
        // validate the 1.2 profile
        boolean validProfile = validateCMDSpec(profile+" (upgraded)",new DOMSource(upgradedProfile));
        System.out.println("Upgraded CMD profile["+profile+"]: "+(validProfile?"VALID":"INVALID"));
        printMessages(validateCMDSpec);
        
        // assertions
        assertTrue(validProfile);
        assertEquals(0, countErrors(validateCMDSpec));
        
        // transform the 1.2 profile into a XSD
        Document profileSchema = transformCMDSpecInXSD(profile+" (upgraded)",new DOMSource(upgradedProfile));
        SchemAnon profileAnon = new SchemAnon(new DOMSource(profileSchema));
        
        // upgrade the record from 1.1 to 1.2
        Document upgradedRecord = upgradeCMDRecord(record);
        
        // validate the 1.2 record
        boolean validRecord = validateCMDRecord(profile+" (upgraded)",profileAnon,record+" (upgraded)",new DOMSource(upgradedRecord));
        System.out.println("Upgraded CMD record["+record+"]: "+(validRecord?"VALID":"INVALID"));
        printMessages(profileAnon);
        
        // assertions
        assertTrue(validRecord);
        assertEquals(0, countErrors(profileAnon));
    }
}
