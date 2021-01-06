/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package eu.clarin.cmdi;

/**
 *
 * @author Twan Goosen <twan@clarin.eu>
 */
public final class CmdNamespaces {

    /**
     * Common namespace for the CMDI record envelope
     */
    public final static String CMD_RECORD_ENVELOPE_NS = "http://www.clarin.eu/cmd/1";

    /**
     * Namespace for cues for tools in a CMDI profile or component specification
     */
    public final static String CMD_SPEC_CUES_NS = "http://www.clarin.eu/cmd/cues/1";

    /**
     * Namespace for schematron rules in schemata
     */
    public final static String SCHEMATRON_NS = "http://purl.oclc.org/dsdl/schematron";

    private final static String CMD_PROFIL_NS_BASE = "http://www.clarin.eu/cmd/1/profiles/";

    /**
     *
     * @param profileId profile to get the namespace for
     * @return the namespace for the payload for a record for the specified
     * profile
     */
    public final static String getCmdRecordPayloadNamespace(String profileId) {
        return CMD_PROFIL_NS_BASE + profileId;
    }

}
