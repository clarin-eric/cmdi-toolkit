/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package eu.clarin.cmdi;

import static eu.clarin.cmdi.Upgrade.IDENTITY;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.xml.transform.Source;
import javax.xml.transform.TransformerException;
import javax.xml.transform.URIResolver;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import org.slf4j.LoggerFactory;

/**
 *
 * @author menzowi
 */
class CachedURLResolver implements URIResolver {
    
    private static final org.slf4j.Logger LOGGER = LoggerFactory.getLogger(CachedURLResolver.class.getName());

    private static final Set<String> pending = new HashSet<>(128);
    private static final Object guard = new Object();
    private static final Object waiter = new Object();

    private final URIResolver resolver;
    private final Path cache;

    public CachedURLResolver(URIResolver resolver,Path cache) {
        this.resolver = resolver;
        this.cache = cache;
    }

    @Override
    public Source resolve(String href, String base) throws TransformerException {
        LOGGER.debug("resolve({}, {})", href, base);
        String uri = href;
        if (base != null && !base.equals("")) {
            try {
                uri = (new URL(new URL(base), href)).toString();
            } catch (MalformedURLException ex) {
                LOGGER.error("couldn't resolve({}, {}) continuing with just {}", href, base, href);
                LOGGER.error("cause:",ex);
            }
        }
        String cacheFile = uri.replaceAll("[^a-zA-Z0-9]", "_");
        LOGGER.debug("check cache for {}", cacheFile);
        
        Source res = null;
        for (;;) {
            boolean doDownload = false;
            synchronized (guard) {
                if (Files.exists(cache.resolve(cacheFile))) {
                    res = new StreamSource(cache.resolve(cacheFile).toFile());
                    LOGGER.debug("loaded {} from cache {}", uri, cacheFile);
                    break;
                } else {
                    synchronized (pending) {
                        if (!pending.contains(uri)) {
                            doDownload = true;
                            pending.add(uri);
                        }
                    } // synchronized (pending)
                }
            } // synchronized (guard)
            
            if (doDownload) {
                synchronized (guard) {
                    StreamResult result = new StreamResult(cache.resolve(cacheFile).toFile());
                    IDENTITY.transform(resolver.resolve(href, base), result);
                    try {
                        result.getOutputStream().close();
                    } catch (IOException ex) {
                        LOGGER.debug("Interrupted while closing cache {}!", cacheFile);
                        LOGGER.debug("Cause:", ex);
                    }
                    LOGGER.debug("stored {} in cache {}", uri, cacheFile);
                    synchronized (pending) {
                        pending.remove(uri);
                        synchronized (waiter) {
                            waiter.notifyAll();
                        } // synchronized (waiter)
                    }// synchronized (pending)
                } // synchronized (guard)
            } else {
                try {
                    synchronized (waiter) {
                        waiter.wait();
                    } // synchronized (waiter)
                } catch (InterruptedException e) {
                    LOGGER.debug("Interrupted while waiting for download of {}!", uri);
                    LOGGER.debug("Cause:", e);
                }
            }
        } // for
        return res;
    }
}