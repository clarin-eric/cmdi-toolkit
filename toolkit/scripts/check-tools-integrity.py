#!/usr/bin/env python3
# -*- coding: utf-8 -*-

##   Title:      Check tools integrity
##   Author:     Sander Maijers <sanmai @@ mpi.nl>
##   Since:      1-8-2012
##   Status:     ALPHA
##   Description:
##   Check the CLARIN tools registry CSV file for problematic 
##   URLs (dead links, etc.) and problematic e-mail-addresses. 
##   Export a table for each record in the registry with the 
##   check results.
##

__author__          = "Sander Maijers"

import              pdb
import				      comm
import              csv, sys
import              urllib.request
import              signal
from                urllib.error import HTTPError,URLError
import              operator
import              progressbar
import              smtplib
import              os.path

URL_record_columns  = ['Reference link (field_tool_reference_link)', 
                       'Documentation link (field_tool_document_link)', 
                       'Webservice link (field_tool_webservice_link)'] # X-

options = args = None


def email(from_addr, 
          to_addrs) :

    def produce_verification_message(from_addr, 
                                     to_addrs,
                                     attach_text = '') : # X-

        from email.mime.multipart       import MIMEMultipart
        from email.mime.text            import MIMEText

        COMMASPACE      = ', '

        msg             = MIMEMultipart()
        msg['Subject']  = "Automatic message for CLARIN database e-mail address check." 
        msg['From']     = from_addr
        msg['To']       = COMMASPACE.join([to_addrs])
        msg['Disposition-Notification-To']  = from_addr
        msg['Original-Recipient']           = to_addr

        return(msg.as_string())

    def SMTP(from_addr, 
             to_addrs, 
             message) :

        comm.communicate(level           = 2, 
                         message         = "Sending automatic probe e-mail [1] ... \n" + message,
                         output_stream1  = sys.stdout)

        server                           = smtplib.SMTP(options.SMTP_server, options.SMTP_port) #port 465 or 587
        server.ehlo()
        server.starttls()
        server.ehlo()
        server.login(from_addr, SMTP_password)

        server.sendmail(from_addr       = from_addr,
                        to_addrs        = to_addrs,
                        msg             = message)

        server.close()

    verification_message                = produce_verification_message(from_addr = options.test_mailbox,
                                                                       to_addrs  = recorded_email_address)

    SMTP(from_addr                  = recorded_email_address,
         to_addrs                   = options.test_mailbox, 
         msg                        = verification_message) #X-



def download_file(destination_directory_path  = None, 
                  destination_file_name       = "", 
                  file_mode                   = None, 
                  base_URL                    = "", 
                  URL                         = "") :

    if base_URL == "" and URL == "" :
         # You need to specify either one of the URL arguments to this function.
        raise URLError
    elif URL == "" :
        URL                   = base_URL + destination_file_name        
    
    destination_file_path = os.path.join(destination_directory_path, destination_file_name)

    try :
        comm.communicate(level   = 2,
                         message = "Downloading {0} to {1} ...".format(URL, destination_file_path),
                         output_streams = sys.stdout)

        response        = urllib.request.urlopen(URL)
    except HTTPError as HTTP_error_obj :
        comm.communicate(level   = 3, 
                         message = "HTTP Error: " + str(e.code) + " with: " + URL, 
                         output_streams = sys.stderr)
    except URLError as URL_error_obj :
        comm.communicate(level   = 3, 
                         message = "URL Error: " + str(e.reason) + " with: " + URL, 
                         output_streams = sys.stderr)
    else :
        with open(destination_file_path, "w" + file_mode) as destination_file :
            destination_file.write(response.read())

def retrieve_tools_CSV() :

    TOOLS_URL                       = "http://www.clarin.eu/export_tools"

    download_file(destination_directory_path = os.path.dirname(options.tools_CSV_file_path),
                  destination_file_name      = os.path.basename(options.tools_CSV_file_path),
                  file_mode                  = "b",
                  URL                        = TOOLS_URL)


def read_tools_CSV() :

    with open(options.tools_CSV_file_path, 
              newline = '') as CSV_file :
        CSV_reader          = csv.DictReader(CSV_file)
        
        CSV_data            = list(CSV_reader)


    return(CSV_data)


def test_URLs(recorded_URLs) :

    def test_URL(URL) :
        try :
            urllib.request.urlopen(url = URL)
        except HTTPError as HTTP_error_obj :
            #HTTP_error_obj.getcode()
            return(False)
        except URLError as URL_error_obj :
            return(False)
        except :
            return(False)
        else :
            return(True)

    assert(len(recorded_URLs) == len(URL_record_columns))
    results         = [''] * len(URL_record_columns)

    for recorded_URL_index, URL in enumerate(recorded_URLs) : # X- check unique urls once

        URL         = URL.strip()

        if URL == '' :
            results[recorded_URL_index]     = 'unspecified'
        else :
            successful_resolution           = test_URL(URL)
            if successful_resolution :
                results[recorded_URL_index] = 'works' 
            else :
                results[recorded_URL_index] = 'problematic'

    return(results)


def test_mails(recorded_email_addresses, 
               minimal_phase = 1, 
               maximal_phase = 2) :

    comm.communicate(level              = 2,
                     message            = "Checking mail fields of records in {0} ...".format(tools_CSV_file_path),
                     output_streams     = sys.stdout)

    def send_out_verification_messages() :
        comm.communicate(level          = 1,
                         message        = "Sending out verification messages ...",
                         output_streams = sys.stdout)

        for recorded_email_address in recorded_email_addresses :
            email(from_addr = recorded_email_address, 
                  to_addrs  = options.test_mailbox)        

    def match_confirmations_with_recorded_email_addresses() :
        pass # X-

    if minimal_phase <= 1   and maximal_phase >= 1 :
        send_out_verification_messages()
    elif minimal_phase <= 2 and maximal_phase >= 2 :
        match_confirmations_with_recorded_email_addresses
    else :
        communicate(level           = 1,
                    message         = "Unknown minimal and/or maximal phase(s) specified to test_mails(): {0} to {1}".format(minimal_phase, maximal_phase),
                    output_streams  = sys.stderr)


def signal_handler(signal, 
                   frame):

    comm.communicate(level          = 1, 
                     message        = "Manually interrupted.",
                     output_streams = sys.stderr)

    sys.exit(0)


def prepare() :

    from optparse import OptionParser
    parser                                  = OptionParser()
    parser.set_defaults(check_mail          = False)
    parser.set_defaults(minimal_phase       = 1)
    parser.set_defaults(maximal_phase       = 2)
    parser.set_defaults(SMTP_server         = None)
    parser.set_defaults(SMTP_server_port    = None)

    parser.set_defaults(tools_CSV_file_path     = '/tmp/export_tools')
    parser.set_defaults(output_CSV_file_path    = '/tmp/output.tab') # X- !!! date_checksumoftoolsCSV.tab

    parser.add_option("--check_mail",
                      dest      = "check_mail",
                      help      = "Perform a check of the e-mail addresses [1] in records, by sending out automatic probe e-mails.", 
                      metavar   = "b")
    parser.add_option("--min_phase",
                      dest      = "minimal_phase",
                      help      = "Skip e-mail address check [1] phases before phase (n).", 
                      metavar   = "n")
    parser.add_option("--max_phase", 
                      dest      = "maximal_phase",
                      help      = "Stop e-mail address check [1] after phase (n).", 
                      metavar   = "n")
    parser.add_option("--SMTP_server", 
                      dest      = "SMTP_server",
                      help      = "SMTP server host name (s) to be used for the e-mail address check [1].", 
                      metavar   = "s")
    parser.add_option("--SMTP_server_port", 
                      dest      = "SMTP_server_port",
                      help      = "SMTP server host port (s) to be used for the e-mail address check [1].", 
                      metavar   = "s")

    parser.add_option("--tools_CSV_file_path", 
                      dest      = "tools_CSV_file_path",
                      help      = "CSV file path (s) for the tools registry that serves as input data.", 
                      metavar   = "s")
    parser.add_option("--output_CSV_file_path", 
                      dest      = "output_CSV_file_path",
                      help      = "CSV file path (s) to output check results to.", 
                      metavar   = "s")

    global options, args
    (options, args)             = parser.parse_args()

    options.minimal_phase       = int(options.minimal_phase) # X- parse int directly
    options.maximal_phase       = int(options.maximal_phase)
    options.check_mail          = bool(options.check_mail)


    if options.check_mail :

        try :
            old_stdout                  = sys.stdout
            sys.stdout                  = sys.stderr

            options.SMTP_user_name      = getpass.getpass("Enter the SMTP user name to be used for the e-mail address check [1] ... \n")
            comm.bell()

            options.SMTP_password       = getpass.getpass("Enter the SMTP password to be used for the e-mail address check [1] ...\n")
            comm.bell()

        finally :
            sys.stdout                  = old_stdout 

        if options.SMTP_server      is None :
            ptions.SMTP_server_port  = input('Enter the SMTP server to be used for the e-mail address check [1] ... \n')

        if options.SMTP_server_port is None :
            options.SMTP_server_port = input('Enter the SMTP server port to be used for the e-mail address check [1] (SSL is assumed) ... \n')

        options.SMTP_server_port = int(options.SMTP_server_port)

def write_check_results(rows) :

    comm.communicate(level              = 2,
                     message            = "Writing results of check to {0} ...".format(options.output_CSV_file_path),
                     output_streams     = sys.stdout)

    with open(options.output_CSV_file_path, 
              mode = 'wt') as CSV_file :

        CSV_writer = csv.DictWriter(CSV_file,
                                    fieldnames  = URL_record_columns,
                                    delimiter   = '\t',
                                    quoting     = csv.QUOTE_MINIMAL) # X-
        CSV_writer.writeheader()
        CSV_writer.writerows(rows)


def check() :

    comm.communicate(level              = 2,
                     message            = "Checking URL fields of records in {0} ...".format(options.tools_CSV_file_path),
                     output_streams     = sys.stdout)

    tools_CSV_data          = read_tools_CSV()

    test_results = []
    progress_bar_obj = progressbar.ProgressBar()

    for record in progress_bar_obj(tools_CSV_data) :
        # Retrieve the attribute values for this record for all attributes that are for URLs
        URL                 = operator.itemgetter(*URL_record_columns)(record)

        # Filter out empty URL strings
        #URL = list(filter(None, URL))

        if len(URL) > 0 :

            test_results    += [dict(zip(URL_record_columns, test_URLs(URL)))]   # list(zip(URL_record_columns, )) #, test_results)

            data = test_results

    return(data)


def main(*args, 
         **kwargs) :

    comm.communicate(level              = 1,
                     message            = "Tool to check integrity of CLARIN tools registry",
                     output_streams     = sys.stdout)

    prepare()

    retrieve_tools_CSV()

    # check_results is a list row objects for DictWriter
    check_results           = check()
    write_check_results(check_results)


if __name__ == '__main__' :
    signal.signal(signal.SIGINT, signal_handler)

    sys.exit(main(*sys.argv))
