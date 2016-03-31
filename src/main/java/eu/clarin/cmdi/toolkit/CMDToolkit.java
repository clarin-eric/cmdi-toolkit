/*
 * Dummy class to allow the tests to load the toolkit resources from the JAR
 * @author menwin
 */
package eu.clarin.cmdi.toolkit;

public class CMDToolkit {
    
    public static final String XSLT_RECORD_UPGRADE = "/toolkit/upgrade/cmd-record-1_1-to-1_2.xsl";
    public static final String XSLT_COMPONENT_UPGRADE = "/toolkit/upgrade/cmd-component-1_1-to-1_2.xsl";
    public static final String XSLT_COMPONENT_DOWNGRADE = "/toolkit/downgrade/cmd-component-1_2-to-1_1.xsl";
    public static final String COMPONENT_SCHEMA = "/toolkit/xsd/cmd-component.xsd";
    //toolkit/sch/cmd-component-best-practices.sch
    //toolkit/sch/cmd-record-best-practices.sch
    //toolkit/xsd/cmd-envelop.xsd
    //toolkit/xslt/clavas2enum.xsl
    //toolkit/xslt/comp2schema.xsl
    public static final String XSLT_PARAM_COMP2SCHEMA_TOOL_KITLOCATION = "cmd-toolkit";
    public static final String SCHEMATRON_PHASE_CMD_COMPONENT_PRE_REGISTRATION = "preRegistration";
    public static final String SCHEMATRON_PHASE_CMD_COMPONENT_POST_REGISTRATION = "postRegistration";
}
