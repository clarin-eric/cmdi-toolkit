package eu.clarin.cmdi;

import eu.clarin.cmdi.toolkit.CMDToolkit;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.function.BiPredicate;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Stream;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import joptsimple.OptionParser;
import joptsimple.OptionSet;
import net.sf.saxon.s9api.DOMDestination;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XdmAtomicValue;
import net.sf.saxon.s9api.XdmNode;
import net.sf.saxon.s9api.XsltTransformer;
import nl.mpi.tla.schemanon.SaxonUtils;
import nl.mpi.tla.schemanon.SchemAnonException;
import org.w3c.dom.Document;

/*
 * Upgrade from CMDI 1.1 to 1.2
 * @author menwin
 */
public class Upgrade {
    
    static final XsltTransformer UPGRADE_1_1_TO_1_2;
    
    static {
        XsltTransformer transformer = null;
        try {        
            transformer = SaxonUtils.buildTransformer(CMDToolkit.class.getResource("/toolkit/upgrade/cmd-record-1_1-to-1_2.xsl")).load();
        } catch (SchemAnonException ex) {
            Logger.getLogger(Upgrade.class.getName()).log(Level.SEVERE, "Couldn't setup CMDI 1.1 to CMDI 1.2 upgrade transformer!", ex);
            System.exit(9);
        } finally {
            UPGRADE_1_1_TO_1_2 = transformer;
        }
    }
    
    protected Source input = null;
    
    public Upgrade(Source input) {
        this.input = input;
    }
    
    Document getOutput() throws ParserConfigurationException, SaxonApiException {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.newDocument();
            DOMDestination dest = new DOMDestination(doc);
            UPGRADE_1_1_TO_1_2.setSource(input);
            UPGRADE_1_1_TO_1_2.setDestination(dest);
            UPGRADE_1_1_TO_1_2.transform();
            return doc;
    }
    
    public static void out(Document doc, OutputStream out) throws IOException, TransformerException {
        TransformerFactory tf = TransformerFactory.newInstance();
        Transformer transformer = tf.newTransformer();
        transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "no");
        transformer.setOutputProperty(OutputKeys.METHOD, "xml");
        transformer.setOutputProperty(OutputKeys.INDENT, "yes");
        transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
        transformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "4");
        transformer.transform(new DOMSource(doc), new StreamResult(new OutputStreamWriter(out, "UTF-8")));
    }

    public static void up(Path path,Path inputPath,Path outputPath,boolean backup,boolean validate) {
        Logger.getLogger(Upgrade.class.getName()).log(Level.INFO, "1.1 record["+path+"]");
        if (backup) {
            Path bak = Paths.get(path.toString()+".bak");
            try {
                Files.copy(path,bak);
            } catch (IOException ex) {
                Logger.getLogger(Upgrade.class.getName()).log(Level.SEVERE, "Failed to upgrade record["+path+"], because backup cannot be created!", ex);
                return;
            }
            Logger.getLogger(Upgrade.class.getName()).log(Level.INFO, "1.1 backup["+bak+"]");
        }

        Path rel = inputPath.relativize(path);
        Path out = outputPath.resolve(rel);
        
        Upgrade upg = new Upgrade(new StreamSource(path.toFile()));
        try {
            Files.createDirectories(out.getParent());
            out(upg.getOutput(),Files.newOutputStream(out,StandardOpenOption.CREATE));
        } catch (IOException | TransformerException | ParserConfigurationException | SaxonApiException ex) {
            Logger.getLogger(Upgrade.class.getName()).log(Level.SEVERE, "Problem upgrading Input["+path+"]!", ex);
        }
        Logger.getLogger(Upgrade.class.getName()).log(Level.INFO, "1.2 record["+out+"]");
    }
    
    private static void help() {
        System.err.println("INF: upgrade-cmdi -i=<DIR/FILE> -o=<DIR> -x=<EXT> -n -v");
        System.err.println("INF: -i=<DIR/FILE> input directory or file (default: current working directory)");
        System.err.println("INF: -o=<DIR>      output directory (default: input directory or stdout)");
        System.err.println("INF: -x=<EXT>      extension of CMD files (default: .xml)");
        System.err.println("INF: -n            don't create a backup when input and output directory are the same, i.e., inplace update (optional)");
        //System.err.println("INF: -v            validate both input (CMDI 1.1) and output (CMDI 1.2) (optional)");
    }

    public static void main(String[] args) {
        String input = ".";
        String output = null;
        String extension = ".xml";
        boolean backup = true;
        boolean validate = false;

        OptionParser parser = new OptionParser( "i:o:x:nv?*" );
        OptionSet options = parser.parse(args);
        if (options.has("i"))
            input = (String)options.valueOf("i");
        if (options.has("o"))
            output = (String)options.valueOf("o");
        if (options.has("x"))
            extension = (String)options.valueOf("x");
        if (options.has("n"))
            backup = false;
        if (options.has("v"))
            validate = true;
        if (options.has("?")) {
            help();
            System.exit(0);
        }
        
        Path inputPath = Paths.get(input);
        if (!Files.isReadable(inputPath)) {
            Logger.getLogger(Upgrade.class.getName()).log(Level.SEVERE, "Input["+input+"] is not readable!");
            System.exit(1);
        }
        if (Files.isDirectory(inputPath)) {
            Path outputPath = Paths.get(output!=null?output:input);
            if (!Files.isWritable(outputPath)) {
                Logger.getLogger(Upgrade.class.getName()).log(Level.SEVERE, "Output["+output+"] is not writable!");
                System.exit(2);
            }
            try {
                if (!Files.isSameFile(inputPath,outputPath))
                    if (backup)
                        backup = false;
            } catch (IOException ex) {
                Logger.getLogger(Upgrade.class.getName()).log(Level.SEVERE, "Problem checking Input["+input+"] and Output["+output+"]!", ex);
                System.exit(3);
            }
            if (backup && !Files.isWritable(inputPath)) {
                Logger.getLogger(Upgrade.class.getName()).log(Level.SEVERE, "Backups cannot be created in Input["+input+"]!");
                System.exit(4);
            }
            final String ext = extension;
            final Path   inp = inputPath;
            final Path   out = outputPath;
            final boolean b  = backup;
            final boolean v  = validate;
            try (Stream<Path> stream = Files.find(inputPath,Integer.MAX_VALUE, new BiPredicate<Path, BasicFileAttributes>() {
                @Override
                public boolean test(Path path, BasicFileAttributes attr) {
                    return String.valueOf(path).endsWith(ext);
                }
            })) {
                stream.forEach((path) -> up(path,inp,out,b,v));
            } catch (IOException ex) {
                Logger.getLogger(Upgrade.class.getName()).log(Level.SEVERE, "Upgrading Input["+inputPath+"] failed!", ex);
            }
        } else {
            Upgrade upg = new Upgrade(new StreamSource(inputPath.toFile()));
            try {
                out(upg.getOutput(),System.out);
            } catch (IOException | TransformerException | ParserConfigurationException | SaxonApiException ex) {
                Logger.getLogger(Upgrade.class.getName()).log(Level.SEVERE, "Problem upgrading Input["+input+"]!", ex);
                System.exit(5);
            }
        }
    }
    
}
