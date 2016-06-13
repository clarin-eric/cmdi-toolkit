package eu.clarin.cmdi;

import eu.clarin.cmdi.toolkit.CMDToolkit;
import eu.clarin.cmdi.validator.CMDISchemaLoader;
import eu.clarin.cmdi.validator.CMDIValidationHandlerAdapter;
import eu.clarin.cmdi.validator.CMDIValidationReport;
import eu.clarin.cmdi.validator.CMDIValidator;
import eu.clarin.cmdi.validator.CMDIValidatorConfig;
import eu.clarin.cmdi.validator.CMDIValidatorException;
import eu.clarin.cmdi.validator.CMDIValidatorInitException;
import eu.clarin.cmdi.validator.SimpleCMDIValidatorProcessor;
import java.io.File;
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
import java.util.HashMap;
import java.util.Map;
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
import javax.xml.transform.URIResolver;
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
import org.slf4j.LoggerFactory;
import org.w3c.dom.Document;

/*
 * Upgrade from CMDI 1.1 to 1.2
 * @author menwin
 */
public class Upgrade {
    
    private static final org.slf4j.Logger LOGGER = LoggerFactory.getLogger(Upgrade.class.getName());
    
    static final Transformer IDENTITY;
    static final XsltExecutable UPGRADE_11TO12;
    static final Map<Path,CachedURLResolver> RESOLVE;
    
    static {
        XsltExecutable transformer = null;
        try {        
            transformer = SaxonUtils.buildTransformer(CMDToolkit.class.getResource("/toolkit/upgrade/cmd-record-1_1-to-1_2.xsl"));
        } catch (SchemAnonException ex) {
            LOGGER.error("Couldn't setup CMDI 1.1 to CMDI 1.2 upgrade transformer!", ex);
            System.exit(9);
        } finally {
            UPGRADE_11TO12 = transformer;
        }
        Transformer tf = null;
        try {
            tf = TransformerFactory.newInstance().newTransformer();
        } catch (TransformerConfigurationException ex) {
            LOGGER.error("Couldn't setup the output transformer!", ex);
            System.exit(9);
        } finally {
            IDENTITY = tf;
            IDENTITY.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "no");
            IDENTITY.setOutputProperty(OutputKeys.METHOD, "xml");
            IDENTITY.setOutputProperty(OutputKeys.INDENT, "yes");
            IDENTITY.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
            IDENTITY.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "4");
        }
        RESOLVE = new HashMap<>();
    }
    
    protected Source input = null;
    protected Path   cache = null;
    
    public Upgrade(Source input,Path cache) {
        this.input = input;
        this.cache = cache;        
    }
    
    public Upgrade(Source input) {
        this(input,Paths.get(".cache"));
    }
    
    public Document getOutput() throws ParserConfigurationException, SaxonApiException {
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        DocumentBuilder builder = factory.newDocumentBuilder();
        Document doc = builder.newDocument();
        DOMDestination dest = new DOMDestination(doc);
        XsltTransformer tf = UPGRADE_11TO12.load();
        if (!RESOLVE.containsKey(cache)) {
            synchronized(RESOLVE) {
                RESOLVE.put(cache, new CachedURLResolver(tf.getURIResolver(), cache));
            }
        }
        tf.setURIResolver(RESOLVE.get(cache));
        tf.setSource(input);
        tf.setDestination(dest);
        tf.transform();
        return doc;
    }
        
    public static void out(Document doc, OutputStream out) throws IOException, TransformerException, ParserConfigurationException, SaxonApiException {
        IDENTITY.transform(new DOMSource(doc), new StreamResult(new OutputStreamWriter(out, "UTF-8")));
    }

    public static void up(Path path, Path inputPath, Path outputPath, Path cache, boolean backup, boolean validate, boolean schematron, CMDIValidatorConfig config) {
        LOGGER.info("1.1 record[{}]", path);
        if (validate)
            validate("1.1", path, schematron, cache, config);
        if (backup) {
            Path bak = Paths.get(path.toString()+".bak");
            try {
                Files.copy(path, bak);
            } catch (IOException ex) {
                LOGGER.error("Failed to upgrade record[{}], because backup cannot be created!", path);
                LOGGER.error("Cause:", ex);
                return;
            }
            LOGGER.info("1.1 backup[{}]", bak);
        }

        Path rel = inputPath.relativize(path);
        Path out = outputPath.resolve(rel);
        try {
            Files.createDirectories(out.getParent());
        } catch (IOException ex) {
            LOGGER.error("Problem creating output[{}]!", out);
            LOGGER.error("Cause:", ex);
        }

        Document doc = null;
        // input might also be the output, so handle the input completely
        try (
            InputStream input   = new FileInputStream(path.toFile());
        ) {
            Upgrade upg = new Upgrade(new StreamSource(input), cache);
            // getting the output doc triggers reading the input
            doc = upg.getOutput();
        } catch (IOException | ParserConfigurationException | SaxonApiException ex) {
            LOGGER.error("Problem upgrading Input[{}]!", path);
            LOGGER.error("Cause:", ex);
        }
        // before handling the output
        if (doc != null) {
            try (
                // if input is still open somehow and the same as output TRUNCATE_EXISTING makes sure we reset the size to 0
                OutputStream output = Files.newOutputStream(out, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
            ) {
                out(doc, output);
            } catch (IOException | TransformerException | ParserConfigurationException | SaxonApiException ex) {
                LOGGER.error("Problem upgrading Input[{}]!", path);
                LOGGER.error("Cause:", ex);
            }
            LOGGER.info("1.2 record[{}]", out);
            if (validate)
                validate("1.2", out, schematron, cache, config);
        }
    }
    
    public static void validate(String version, Path rec, boolean schematron, Path cache, CMDIValidatorConfig config) {
        try {
            CMDIValidator validator = new CMDIValidator(config, rec.toFile(), new Handler(version));
            SimpleCMDIValidatorProcessor processor = new SimpleCMDIValidatorProcessor();
            processor.process(validator);
        } catch (CMDIValidatorInitException | CMDIValidatorException ex) {
            LOGGER.error("Problem validating Record[{}]!", rec);
            LOGGER.error("Cause:", ex);
        }
    }
    
    private static class Handler extends CMDIValidationHandlerAdapter {
        
        private String version;
        
        public Handler(String version) {
            super();
            this.version = version;
        }
        
        @Override
        public void onValidationReport(final CMDIValidationReport report)
                throws CMDIValidatorException {
            final File file = report.getFile();
            int skip = 0;
            switch (report.getHighestSeverity()) {
            case INFO:
                LOGGER.info("{} record[{}] is valid", version, file);
                break;
            case WARNING:
                LOGGER.warn("{} record[{}] is valid (with warnings):", version, file);
                for (CMDIValidationReport.Message msg : report.getMessages()) {
                    if (msg.getMessage().contains("Failed to read schema document ''")) {
                        skip++;
                        continue;
                    }
                    if ((msg.getLineNumber() != -1) && (msg.getColumnNumber() != -1)) {
                        LOGGER.warn(" ({}) {} [line={}, column={}]", msg.getSeverity().getShortcut(), msg.getMessage(), msg.getLineNumber(), msg.getColumnNumber());
                    } else {
                        LOGGER.warn(" ({}) {}", msg.getSeverity().getShortcut(), msg.getMessage());
                    }
                }
                break;
            case ERROR:
                LOGGER.error("{} record[{}] is invalid:", version, file);
                for (CMDIValidationReport.Message msg : report.getMessages()) {
                    if (msg.getMessage().contains("Failed to read schema document ''")) {
                        skip++;
                        continue;
                    }
                    if ((msg.getLineNumber() != -1) && (msg.getColumnNumber() != -1)) {
                        LOGGER.error(" ({}) {} [line={}, column={}]", msg.getSeverity().getShortcut(), msg.getMessage(), msg.getLineNumber(), msg.getColumnNumber());
                    } else {
                        LOGGER.error(" ({}) {}", msg.getSeverity().getShortcut(), msg.getMessage());
                    }
                }
                break;
            default:
                throw new CMDIValidatorException("unexpected severity: " +
                        report.getHighestSeverity());
            } // switch
            if (skip>0)
                LOGGER.warn("Skipped [{}] warnings due to lax validation of foreign namespaces", skip);
        }
    } // class Handler    
    
    private static void help() {
        System.err.println("INF: java -jar upgrade-cmdi.jar <OPTION>*, where <OPTION> is one of those:");
        System.err.println("INF: -i=<DIR/FILE> input directory or file (default: current working directory)");
        System.err.println("INF: -o=<DIR>      output directory (default: input directory or stdout)");
        System.err.println("INF: -c=<DIR>      cache directory (default: .cache)");
        System.err.println("INF: -x=<EXT>      extension of CMD files (default: .xml)");
        System.err.println("INF: -B            don't create a backup when input and output directory are the same, i.e., inplace update (default: backup)");
        System.err.println("INF: -P            single threaded batch conversion (default: parallel)");
        System.err.println("INF: -V            don't validate (XSD+Schematron) input (CMDI 1.1) and output (CMDI 1.2) (default: validate)");
        System.err.println("INF: -S            don't validate (Schematron) input (CMDI 1.1) and output (CMDI 1.2) against (default: schematron)");
        System.err.println("INF: -C            don't clean the cache directory (default: clean cache)");
    }

    public static void main(String[] args) {
        String input = ".";
        String output = null;
        String cache = null;
        String extension = ".xml";
        boolean backup = true;
        boolean validate = true;
        boolean schematron = true;
        boolean parallel = true;
        boolean clean = true;

        OptionParser parser = new OptionParser("i:o:c:x:BPVSC?*");
        OptionSet options = parser.parse(args);
        if (options.has("i"))
            input = (String)options.valueOf("i");
        if (options.has("o"))
            output = (String)options.valueOf("o");
        if (options.has("c"))
            cache = (String)options.valueOf("c");
        if (options.has("x"))
            extension = (String)options.valueOf("x");
        if (options.has("B"))
            backup = false;
        if (options.has("P"))
            parallel = false;
        if (options.has("V"))
            validate = false;
        if (options.has("S"))
            schematron = false;
        if (options.has("C"))
            clean = false;
        if (options.has("?")) {
            help();
            System.exit(0);
        }

        if (cache == null)
            cache = ".cache";
        Path cachePath = Paths.get(cache);
        if (Files.isDirectory(cachePath) && clean) {
            try {
                Files.delete(cachePath);
            } catch (IOException ex) {
                LOGGER.error("Problem cleaning cache[{}]!", cache);
                LOGGER.error("Cause:", ex);
                System.exit(6);
            }
        }
        if (!Files.isDirectory(cachePath)) {
            try {
                Files.createDirectories(cachePath);
            } catch (IOException ex) {
                LOGGER.error("Problem creating cache[{}]!", cache);
                LOGGER.error("Cause:", ex);
                System.exit(6);
            }
        }
        if (!Files.isReadable(cachePath)) {
            LOGGER.error("Cache[{}] is not readable!", cache);
            System.exit(6);
        }
        if (!Files.isWritable(cachePath)) {
            LOGGER.error("Cache[{}] is not writable!", cache);
            System.exit(6);
        }
        
        Path inputPath = Paths.get(input);
        if (!Files.isReadable(inputPath)) {
            LOGGER.error("Input[{}] is not readable!", input);
            System.exit(1);
        }
        
        CMDIValidatorConfig.Builder builder = new CMDIValidatorConfig.Builder(inputPath.toFile(), new Handler("0")).socketTimeout(0);
        if (!schematron)
            builder = builder.disableSchematron();
        builder.schemaLoader(new CMDISchemaLoader(cachePath.toFile()));
        CMDIValidatorConfig config = builder.build();
 
        if (Files.isDirectory(inputPath)) {
            Path outputPath = Paths.get(output!=null?output:input);
            if (!Files.isDirectory(outputPath)) {
                LOGGER.error("Output[{}] is not a directory!", output);
                System.exit(2);
            }
            if (!Files.isWritable(outputPath)) {
                LOGGER.error("Output[{}] is not writable!", output);
                System.exit(2);
            }
            try {
                if (!Files.isSameFile(inputPath, outputPath))
                    if (backup)
                        backup = false;
            } catch (IOException ex) {
                LOGGER.error("Problem checking Input[{}] and Output[{}]!", input, output);
                LOGGER.error("Cause:", ex);
                System.exit(3);
            }
            if (backup && !Files.isWritable(inputPath)) {
                LOGGER.error("Backups cannot be created in Input[{}]!", input);
                System.exit(4);
            }
            final String ext = extension;
            final Path   inp = inputPath;
            final Path   out = outputPath;
            final Path   cch = cachePath;
            final boolean b  = backup;
            final boolean v  = validate;
            final boolean s  = schematron;
            final boolean p  = parallel;
            final CMDIValidatorConfig c = config;
            try (Stream<Path> stream = Files.find(inputPath,Integer.MAX_VALUE, (Path path, BasicFileAttributes attr) -> String.valueOf(path).endsWith(ext))) {
                Stream<Path> stream2 = stream;
                if (p)
                    stream2 = stream.parallel();
                stream2.forEach((path) -> up(path, inp, out, cch, b, v, s, c));
            } catch (IOException ex) {
                LOGGER.error("Upgrading Input[{}] failed!", inputPath);
                LOGGER.error("Cause:", ex);
            }
        } else {
            Upgrade upg = new Upgrade(new StreamSource(inputPath.toFile()));
            try {
                out(upg.getOutput(), System.out);
            } catch (IOException | TransformerException | ParserConfigurationException | SaxonApiException ex) {
                LOGGER.error("Problem upgrading Input[{}]!", input);
                LOGGER.error("Cause:", ex);
                System.exit(5);
            }
        }
    }
    
}
