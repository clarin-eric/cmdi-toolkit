/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package eu.clarin.cmd.toolkit;

import java.io.File;
import java.io.IOException;
import java.net.URL;
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
import net.sf.saxon.s9api.XPathCompiler;
import net.sf.saxon.s9api.XPathExecutable;
import net.sf.saxon.s9api.XPathSelector;
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
    XsltTransformer downgradeCMDSpec = null;
    XsltTransformer upgradeCMDRec = null;
    XsltTransformer transformCMDSpecInXSD = null;
    SchemAnon validateCMDSpec = null;
    SchemAnon validateCMDoldSpec = null;
    SchemAnon validateCMDEnvelop = null;

    @Before
    public void setUp() {
        try {
            upgradeCMDSpec = SaxonUtils.buildTransformer(CMDToolkit.class.getResource("/toolkit/upgrade/cmd-component-1_1-to-1_2.xsl")).load();
            downgradeCMDSpec = SaxonUtils.buildTransformer(CMDToolkit.class.getResource("/toolkit/downgrade/cmd-component-1_2-to-1_1.xsl")).load();
            upgradeCMDRec = SaxonUtils.buildTransformer(CMDToolkit.class.getResource("/toolkit/upgrade/cmd-record-1_1-to-1_2.xsl")).load();
            transformCMDSpecInXSD = SaxonUtils.buildTransformer(CMDToolkit.class.getResource("/toolkit/xslt/comp2schema.xsl")).load();
            validateCMDSpec = new SchemAnon(CMDToolkit.class.getResource("/toolkit/xsd/cmd-component.xsd").toURI().toURL());            
            validateCMDoldSpec = new SchemAnon(new URL("http://infra.clarin.eu/cmd/general-component-schema.xsd"));
//            validateCMDoldSpec = new SchemAnon(new URL("file:///Users/menzowi/Documents/Projects/CLARIN/CMDI/CMDI-1.1/src/toolkit/general-component-schema.xsd"));
            validateCMDEnvelop = new SchemAnon(CMDToolkit.class.getResource("/toolkit/xsd/cmd-envelop.xsd").toURI().toURL());
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

    protected boolean xpath(Document doc,String xpath) throws Exception {
        XPathCompiler xpc   = SaxonUtils.getProcessor().newXPathCompiler();
        xpc.declareNamespace("cmd","http://www.clarin.eu/cmd/1");
        XPathExecutable xpe = xpc.compile(xpath);
        XPathSelector xps   = xpe.load();
        xps.setContextItem(SaxonUtils.getProcessor().newDocumentBuilder().wrap(doc));
        return xps.effectiveBooleanValue();
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

    protected Document downgradeCMDSpec(String spec) throws Exception {
        System.out.println("Downgrade CMD spec["+spec+"]");
        return transform(downgradeCMDSpec,new javax.xml.transform.stream.StreamSource(new java.io.File(TestCMDToolkit.class.getResource(spec).toURI())));
    }

    protected Document downgradeCMDSpec(String spec,Source src) throws Exception {
        System.out.println("Downgrade CMD spec["+spec+"]");
        return transform(downgradeCMDSpec,src);
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
        boolean res = validateCMDSpec.validate(src);
        System.out.println("CMD spec["+spec+"]: "+(res?"VALID":"INVALID"));
        printMessages(validateCMDSpec);
        return res;
    }

    protected boolean validateCMDoldSpec(String spec,Source src) throws Exception {
        System.out.println("Validate CMD 1.1 spec["+spec+"]");
        boolean res = validateCMDoldSpec.validate(src);
        System.out.println("CMD old spec["+spec+"]: "+(res?"VALID":"INVALID"));
        printMessages(validateCMDoldSpec);
        return res;
    }

    protected boolean validateCMDSpec(String spec) throws Exception {
        return validateCMDSpec(spec,new StreamSource(new java.io.File(TestCMDToolkit.class.getResource(spec).toURI())));
    }

    protected boolean validateCMDRecord(String spec,SchemAnon anon,String rec,Source src) throws Exception {
        System.out.println("Validate CMD record["+rec+"] against spec["+spec+"]");
        boolean res = anon.validate(src);
        System.out.println("CMD record["+rec+"]: "+(res?"VALID":"INVALID"));
        printMessages(anon);
        return res;
    }

    protected boolean validateCMDEnvelop(String rec,Source src) throws Exception {
        System.out.println("Validate envelop CMD rec["+rec+"]");
        boolean res = validateCMDEnvelop.validate(src);
        System.out.println("CMD rec["+rec+"] evelop: "+(res?"VALID":"INVALID"));
        printMessages(validateCMDEnvelop);
        return res;
    }

    protected boolean validateCMDEnvelop(String rec) throws Exception {
        return validateCMDEnvelop(rec,new StreamSource(new java.io.File(TestCMDToolkit.class.getResource(rec).toURI())));
    }

    @Test
    public void testAdelheid() throws Exception {
        String profile = "/toolkit/Adelheid/profiles/clarin.eu:cr1:p_1311927752306.xml";
        String record  = "/toolkit/Adelheid/records/Adelheid.cmdi";

        // upgrade the profile from 1.1 to 1.2
        Document upgradedProfile = upgradeCMDSpec(profile);

        // validate the 1.2 profile
        boolean validProfile = validateCMDSpec(profile+" (upgraded)",new DOMSource(upgradedProfile));

        // assertions
        // the upgraded profile should be a valid CMDI 1.2 profile
        assertTrue(validProfile);
        // so there should be no errors
        assertEquals(0, countErrors(validateCMDSpec));

        // transform the 1.2 profile into a XSD
        Document profileSchema = transformCMDSpecInXSD(profile+" (upgraded)",new DOMSource(upgradedProfile));
        SchemAnon profileAnon = new SchemAnon(new DOMSource(profileSchema));

        // upgrade the record from 1.1 to 1.2
        Document upgradedRecord = upgradeCMDRecord(record);

        // validate the 1.2 record
        boolean validRecord = validateCMDRecord(profile+" (upgraded)",profileAnon,record+" (upgraded)",new DOMSource(upgradedRecord));

        // assertions
        // the upgraded record should be a valid CMDI 1.2 record
        assertTrue(validRecord);
        // so there should be no errors
        assertEquals(0, countErrors(profileAnon));
        
        // downgrade the 1.2 profile to 1.1
        Document oldProfile = downgradeCMDSpec(profile+" (upgraded)",new DOMSource(upgradedProfile));
        
        // validate the 1.1 profile
        boolean validOldProfile = validateCMDoldSpec(profile+" (downgraded)",new DOMSource(oldProfile));

        // assertions
        // the downgraded profile should be a valid CMDI 1.1 profile
        assertTrue(validOldProfile);
        // so there should be no errors
        assertEquals(0, countErrors(validateCMDoldSpec));        
    }

    @Test
    public void testAdelheid2() throws Exception {
        String profile = "/toolkit/Adelheid/profiles/clarin.eu:cr1:p_1311927752306_1_2.xml";
        String record  = "/toolkit/Adelheid/records/Adelheid_1_2-invalid.cmdi";

        // validate the 1.2 profile
        boolean validProfile = validateCMDSpec(profile,new javax.xml.transform.stream.StreamSource(new java.io.File(TestCMDToolkit.class.getResource(profile).toURI())));

        // assertions
        // the upgraded profile should be a valid CMDI 1.2 profile
        assertTrue(validProfile);
        // so there should be no errors
        assertEquals(0, countErrors(validateCMDSpec));

        Document profileSchema = transformCMDSpecInXSD(profile,new javax.xml.transform.stream.StreamSource(new java.io.File(TestCMDToolkit.class.getResource(profile).toURI())));
        SchemAnon profileAnon = new SchemAnon(new DOMSource(profileSchema));

        // validate the 1.2 record
        boolean validRecord = validateCMDRecord(profile,profileAnon,record,new javax.xml.transform.stream.StreamSource(new java.io.File(TestCMDToolkit.class.getResource(record).toURI())));

        // assertions
        // the record should be a invalid as it misses a the required CoreVersion attribute
        assertFalse(validRecord);

        // downgrade the 1.2 profile to 1.1
        Document oldProfile = downgradeCMDSpec(profile);
        
        // validate the 1.1 profile
        boolean validOldProfile = validateCMDoldSpec(profile+" (downgraded)",new DOMSource(oldProfile));

        // assertions
        // the downgraded profile should be a valid CMDI 1.1 profile
        assertTrue(validOldProfile);
        // so there should be no errors
        assertEquals(0, countErrors(validateCMDoldSpec));        
    }

    @Test
    public void testSundhed() throws Exception {
        String profile = "/toolkit/TEI/profiles/clarin.eu:cr1:p_1380106710826.xml";
        String record  = "/toolkit/TEI/records/sundhed_dsn.teiHeader.ref.xml";

        // upgrade the profile from 1.1 to 1.2
        Document upgradedProfile = upgradeCMDSpec(profile);

        // validate the 1.2 profile
        boolean validProfile = validateCMDSpec(profile+" (upgraded)",new DOMSource(upgradedProfile));

        // assertions
        // the upgraded profile should be a valid CMDI 1.2 profile and 'ref' named Attributes should validate
        assertTrue(validProfile);
        // so there should be no errors
        assertEquals(0, countErrors(validateCMDSpec));

        // transform the 1.2 profile into a XSD
        Document profileSchema = transformCMDSpecInXSD(profile+" (upgraded)",new DOMSource(upgradedProfile));
        SchemAnon profileAnon = new SchemAnon(new DOMSource(profileSchema));

        // upgrade the record from 1.1 to 1.2
        Document upgradedRecord = upgradeCMDRecord(record);

        // validate the 1.2 record
        boolean validRecord = validateCMDRecord(profile+" (upgraded)", profileAnon, record+" (upgraded)", new DOMSource(upgradedRecord));

        // assertions
        // the upgraded record should be a valid CMDI 1.2 record
        assertTrue(validRecord);

        // so there should be no errors
        assertEquals(0, countErrors(profileAnon));
        
        // downgrade the 1.2 profile to 1.1
        Document oldProfile = downgradeCMDSpec(profile+" (upgraded)",new DOMSource(upgradedProfile));
        
        // validate the 1.1 profile
        boolean validOldProfile = validateCMDoldSpec(profile+" (downgraded)",new DOMSource(oldProfile));

        // assertions
        // the downgraded profile should be a valid CMDI 1.1 profile
        assertTrue(validOldProfile);
        // so there should be no errors
        assertEquals(0, countErrors(validateCMDoldSpec));        
    }

    @Test
    public void testTEI() throws Exception {
        String record  = "/toolkit/TEI/records/sundhed_dsn.teiHeader.ref.xml";

        // upgrade the record from 1.1 to 1.2
        Document upgradedRecord = upgradeCMDRecord(record);

        // assertions
        // the @ref attributes on the elements should stay as they are
        assertTrue(xpath(upgradedRecord,"//*:author/*:name/@ref"));
    }

    @Test
    public void testSuccessor() throws Exception {
        String validRecord  = "/toolkit/successor/profiles/successor-valid.xml";
        String invalidRecord  = "/toolkit/successor/profiles/successor-invalid.xml";

        // assertions
        assertTrue(validateCMDSpec(validRecord));
        assertFalse(validateCMDSpec(invalidRecord));
    }

    @Test
    public void testOLAC() throws Exception {
        String profile = "/toolkit/OLAC/profiles/OLAC-DcmiTerms.xml";
        String record  = "/toolkit/OLAC/records/org_rosettaproject-record.xml";

        // upgrade the profile from 1.1 to 1.2
        Document upgradedProfile = upgradeCMDSpec(profile);

        // validate the 1.2 profile
        boolean validProfile = validateCMDSpec(profile+" (upgraded)",new DOMSource(upgradedProfile));

        // assertions
        // the upgraded profile should be a valid CMDI 1.2 profile
        assertTrue(validProfile);
        // so there should be no errors
        assertEquals(0, countErrors(validateCMDSpec));

        // transform the 1.2 profile into a XSD
        Document profileSchema = transformCMDSpecInXSD(profile+" (upgraded)",new DOMSource(upgradedProfile));
        SchemAnon profileAnon = new SchemAnon(new DOMSource(profileSchema));

        // upgrade the record from 1.1 to 1.2
        Document upgradedRecord = upgradeCMDRecord(record);

        // validate the 1.2 record
        boolean validRecord = validateCMDRecord(profile+" (upgraded)",profileAnon,record+" (upgraded)",new DOMSource(upgradedRecord));

        // assertions
        assertFalse(validRecord);

        // downgrade the 1.2 profile to 1.1
        Document oldProfile = downgradeCMDSpec(profile+" (upgraded)",new DOMSource(upgradedProfile));
        
        // validate the 1.1 profile
        boolean validOldProfile = validateCMDoldSpec(profile+" (downgraded)",new DOMSource(oldProfile));

        // assertions
        // the downgraded profile should be a valid CMDI 1.1 profile
        assertTrue(validOldProfile);
        // so there should be no errors
        assertEquals(0, countErrors(validateCMDoldSpec));        
    }

    @Test
    public void testCMD() throws Exception {
        String profile = "/toolkit/CMD/profiles/components-invalid.xml";

        // validate the 1.2 profile
        boolean validProfile = validateCMDSpec(profile,new javax.xml.transform.stream.StreamSource(new java.io.File(TestCMDToolkit.class.getResource(profile).toURI())));

        // assertions
        assertFalse(validProfile);
    }


}
