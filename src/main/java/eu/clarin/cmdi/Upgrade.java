package eu.clarin.cmdi;

import eu.clarin.cmdi.toolkit.CMDToolkit;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Stream;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import joptsimple.OptionParser;
import joptsimple.OptionSet;
import net.sf.saxon.s9api.DOMDestination;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XsltExecutable;
import net.sf.saxon.s9api.XsltTransformer;
import nl.mpi.tla.schemanon.SaxonUtils;
import nl.mpi.tla.schemanon.SchemAnonException;
import org.w3c.dom.Document;

/*
 * Upgrade from CMDI 1.1 to 1.2
 * @author menwin
 */
public class Upgrade {
    
    static final Logger LOGGER = Logger.getLogger(Upgrade.class.getName());
    
    static final Transformer IDENTITY;
    static final XsltExecutable UPGRADE_11TO12;
    
    static {
        XsltExecutable transformer = null;
        try {        
            transformer = SaxonUtils.buildTransformer(CMDToolkit.class.getResource("/toolkit/upgrade/cmd-record-1_1-to-1_2.xsl"));
        } catch (SchemAnonException ex) {
            LOGGER.log(Level.SEVERE, "Couldn't setup CMDI 1.1 to CMDI 1.2 upgrade transformer!", ex);
            System.exit(9);
        } finally {
            UPGRADE_11TO12 = transformer;
        }
        Transformer tf = null;
        try {
            tf = TransformerFactory.newInstance().newTransformer();
        } catch (TransformerConfigurationException ex) {
            LOGGER.log(Level.SEVERE, "Couldn't setup the output transformer!", ex);
            System.exit(9);
        } finally {
            IDENTITY = tf;
            IDENTITY.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "no");
            IDENTITY.setOutputProperty(OutputKeys.METHOD, "xml");
            IDENTITY.setOutputProperty(OutputKeys.INDENT, "yes");
            IDENTITY.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
            IDENTITY.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "4");
        }
    }
    
    protected Source input = null;
    
    public Upgrade(Source input) {
        this.input = input;
    }
    
    public Document getOutput() throws ParserConfigurationException, SaxonApiException {
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        DocumentBuilder builder = factory.newDocumentBuilder();
        Document doc = builder.newDocument();
        DOMDestination dest = new DOMDestination(doc);
        XsltTransformer tf = UPGRADE_11TO12.load();
        tf.setSource(input);
        tf.setDestination(dest);
        tf.transform();
        return doc;
    }
    
    public static void out(Document doc, OutputStream out) throws IOException, TransformerException, ParserConfigurationException, SaxonApiException {
        IDENTITY.transform(new DOMSource(doc), new StreamResult(new OutputStreamWriter(out, "UTF-8")));
    }

    public static void up(Path path,Path inputPath,Path outputPath,boolean backup,boolean validate) {
        LOGGER.log(Level.INFO, "1.1 record[{0}]", path);
        if (backup) {
            Path bak = Paths.get(path.toString()+".bak");
            try {
                Files.copy(path, bak);
            } catch (IOException ex) {
                LOGGER.log(Level.SEVERE, "Failed to upgrade record[{0}], because backup cannot be created!", path);
                LOGGER.log(Level.SEVERE, "Cause:", ex);
                return;
            }
            LOGGER.log(Level.INFO, "1.1 backup[{0}]", bak);
        }

        Path rel = inputPath.relativize(path);
        Path out = outputPath.resolve(rel);
        try {
            Files.createDirectories(out.getParent());
        } catch (IOException ex) {
            LOGGER.log(Level.SEVERE, "Problem creating output[{0}]!", out);
            LOGGER.log(Level.SEVERE, "Cause:", ex);
        }

        Document doc = null;
        // input might also be the output, so handle the input completely
        try (
            InputStream input   = new FileInputStream(path.toFile());
        ) {
            Upgrade upg = new Upgrade(new StreamSource(input));
            // getting the output doc triggers reading the input
            doc = upg.getOutput();
        } catch (IOException | ParserConfigurationException | SaxonApiException ex) {
            LOGGER.log(Level.SEVERE, "Problem upgrading Input[{0}]!", path);
            LOGGER.log(Level.SEVERE, "Cause:", ex);
        }
        // before handling the output
        if (doc != null) {
            try (
                // if input is still open somehow and the same as output TRUNCATE_EXISTING makes sure we reset the size to 0
                OutputStream output = Files.newOutputStream(out, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
            ) {
                out(doc, output);
            } catch (IOException | TransformerException | ParserConfigurationException | SaxonApiException ex) {
                LOGGER.log(Level.SEVERE, "Problem upgrading Input[{0}]!", path);
                LOGGER.log(Level.SEVERE, "Cause:", ex);
            }
            LOGGER.log(Level.INFO, "1.2 record[{0}]", out);
        }
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
        boolean parallel = true;

        OptionParser parser = new OptionParser("i:o:x:nv?*");
        OptionSet options = parser.parse(args);
        if (options.has("i"))
            input = (String)options.valueOf("i");
        if (options.has("o"))
            output = (String)options.valueOf("o");
        if (options.has("x"))
            extension = (String)options.valueOf("x");
        if (options.has("n"))
            backup = false;
        if (options.has("s"))
            parallel = false;
        if (options.has("v"))
            validate = true;
        if (options.has("?")) {
            help();
            System.exit(0);
        }
        
        Path inputPath = Paths.get(input);
        if (!Files.isReadable(inputPath)) {
            LOGGER.log(Level.SEVERE, "Input[{0}] is not readable!", input);
            System.exit(1);
        }
        if (Files.isDirectory(inputPath)) {
            Path outputPath = Paths.get(output!=null?output:input);
            if (!Files.isWritable(outputPath)) {
                LOGGER.log(Level.SEVERE, "Output[{0}] is not writable!", output);
                System.exit(2);
            }
            try {
                if (!Files.isSameFile(inputPath, outputPath))
                    if (backup)
                        backup = false;
            } catch (IOException ex) {
                LOGGER.log(Level.SEVERE, "Problem checking Input[{0}] and Output[{1}]!", new Object[]{input, output});
                LOGGER.log(Level.SEVERE, "Cause:", ex);
                System.exit(3);
            }
            if (backup && !Files.isWritable(inputPath)) {
                LOGGER.log(Level.SEVERE, "Backups cannot be created in Input[{0}]!", input);
                System.exit(4);
            }
            final String ext = extension;
            final Path   inp = inputPath;
            final Path   out = outputPath;
            final boolean b  = backup;
            final boolean v  = validate;
            final boolean p  = parallel;
            try (Stream<Path> stream = Files.find(inputPath,Integer.MAX_VALUE, (Path path, BasicFileAttributes attr) -> String.valueOf(path).endsWith(ext))) {
                Stream<Path> s = stream;
                if (p)
                    s = stream.parallel();
                s.forEach((path) -> up(path, inp, out, b, v));
            } catch (IOException ex) {
                LOGGER.log(Level.SEVERE, "Upgrading Input[{0}] failed!", inputPath);
                LOGGER.log(Level.SEVERE, "Cause:", ex);
            }
        } else {
            Upgrade upg = new Upgrade(new StreamSource(inputPath.toFile()));
            try {
                out(upg.getOutput(), System.out);
            } catch (IOException | TransformerException | ParserConfigurationException | SaxonApiException ex) {
                LOGGER.log(Level.SEVERE, "Problem upgrading Input[{0}]!", input);
                LOGGER.log(Level.SEVERE, "Cause:", ex);
                System.exit(5);
            }
        }
    }
    
}
