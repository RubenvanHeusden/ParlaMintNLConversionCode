<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="xs math xd"
    version="3.0">
    <xsl:output method="xml" indent="yes"/>

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Dec 15, 2020</xd:p>
            <xd:p><xd:b>Author:</xd:b> Ruben van Heusden</xd:p>
            <xd:p>First revision of the script used to convert the Dutch Parliamentary data to the TEI format</xd:p>
            <xd:p>This script requires the metadata of the files to be available in a separate folder in order to read some of the essential metadata from there.</xd:p>
        </xd:desc>
    </xd:doc>

    <!-- DECLARATION OF VARIABLES-->

    <!-- A variable that extracts the filename of the metadata file from the file header and returns the document -->

    <xsl:variable name="metadata_file" select="
        let $metadata := tokenize(officiele-publicatie/metadata/meta/@content, '/')
        return doc('metadata/' || $metadata[last()-1] || '_' || $metadata[last()])"/>


    <!-- A variable that extracts the identifier of the current document.  This is used in the ID declaration of the document-->

    <xsl:variable name="document_id" select="$metadata_file/metadata_gegevens/metadata[@name='DC.identifier']/@content"/>

    <!-- A variable that contains the type of house the document is from, can be either 'Eerste Kamer' or 'Tweede Kamer' -->

    <xsl:variable name="kamer_type" select = "
        let $kamer_id := tokenize($document_id, '-')[2]
        return if ($kamer_id='ek')
        then 'Eerste Kamer'
        else 'Tweede Kamer'"/>


    <xsl:variable name="english_chamber_text" select="
        if ($kamer_type='Eerste Kamer')
        then 'Upper House'
        else 'Lower House'
        "/>

    <xsl:variable name="chamber_ref" select="
        if ($kamer_type='Eerste Kamer')
        then '#EK'
        else '#TK'
        "/>


    <!-- Value that contains the date of the document. Used for timestamping the documents and statements, as well as determining the proper chair of meeting-->

    <xsl:variable name="current_date" select = "xs:date($metadata_file/metadata_gegevens/metadata[@name='OVERHEIDop.datumVergadering']/@content)"/>


    <!-- Variable that contains the chair of the house in question in the document, extracted from a file with all chairs in the period 2015-2020.
        Calculated by using the date of the documnet-->

    <xsl:variable name="voorzitter" select="
        if ($kamer_type='Eerste Kamer')
        then doc('voorzitters.xml')/voorzitters-informatie/eerste-kamer/voorzitter[xs:date(@start) &lt;= $current_date and xs:date(@end) >= $current_date]/@name
        else doc('voorzitters.xml')/voorzitters-informatie/tweede-kamer/voorzitter[xs:date(@start) &lt;= $current_date and xs:date(@end) >= $current_date]/@name
        "/>


    <!-- Variable that contains the unique identifier of the chair to be used in the 'who' attribate of the speeches -->

    <xsl:variable name="voorzitter_id" select="'#' || string-join(for $i in tokenize($voorzitter, '\s') return $i, ' ')"/>


    <!-- Variable that contains the year in which the meeting was held -->

    <xsl:variable name="current_year" select="year-from-date($current_date)" />


    <!-- Variable containing the number of speeches contained in the document (actually utterances) (TODO)-->
    <xsl:variable name="number_of_speeches" select="count(officiele-publicatie/handelingen/*/spreekbeurt)" />

    <!--  Variable containing (an approximation of) the number of words used in the documents (Current approach is counting a bit too much content I think )(TODO)-->

    <xsl:variable name="number_of_words" select="count(//text()/tokenize(normalize-space(.),'\s'))"/>

    <xsl:variable name = "chamber_number" select="
        let $kamer_id := tokenize($document_id, '-')[2]
        return if ($kamer_id='ek')
        then (if($current_date >= xs:date('2019-06-11')) then '36-upper' else ( if($current_date >= xs:date('2015-06-09')) then '35-upper' else '34-upper'))
        else (if ($current_date >= xs:date('2022-01-09')) then '30-lower' else ( if($current_date >= xs:date('2017-10-27')) then '29-lower' else '28-lower'))"/>

    <xsl:variable name = "chamber_ref_num" select="
        let $kamer_id := tokenize($document_id, '-')[2]
        return if ($kamer_id='ek')
        then (if($current_date >= xs:date('2019-06-11')) then '#EK.36' else ( if($current_date >= xs:date('2015-06-09')) then '#EK.35' else '#EK.34'))
        else (if ($current_date >= xs:date('2022-01-09')) then '#TK.30' else ( if($current_date >= xs:date('2017-10-27')) then '#TK.29' else '#TK.28'))"/>

    <xsl:variable name="id" select="
        'ParlaMint-NL_' ||  $current_date ||'-' || lower-case(replace($kamer_type, ' ', '')) || '-' ||$metadata_file/metadata_gegevens/metadata[@name='OVERHEIDop.handelingenItemNummer']/@content  "/>

    <!-- END OF VARIABLE DECLARATION-->

    <xd:doc>
        <xd:desc> Root template</xd:desc>
    </xd:doc>
    <xsl:template match="/">

    <!-- START OF CONVERSION CODE-->

        <TEI xmlns="http://www.tei-c.org/ns/1.0" ana="#reference" xml:lang="nl">
            <xsl:attribute name="ana" select=" if ($current_date >= xs:date('2019-10-01')) then '#covid' else '#reference' "  />
            <xsl:attribute name="xml:id">
                <xsl:value-of select="$id"/>
            </xsl:attribute>
            <!-- Declaration  of the TEI header (This might be done in a separate file in a next iteration) (TODO) -->
            <teiHeader>
            <fileDesc>

                <!-- The title statement this contains (at least) the following information
                    - The title of the document
                    - The persons involved in the conversion and their responsibilities
                    - The funder of the research
                -->
                <titleStmt>
                    <title type="main" xml:lang="en">Dutch parliamentary corpus ParlaMint-NL, <xsl:value-of select="$english_chamber_text || ' '"/> <xsl:value-of select="$current_date" /> [ParlaMint]</title>
                    <title type="main" xml:lang="nl">Corpus van het Nederlandse Parlement ParlaMint-NL, <xsl:value-of select="$kamer_type || ' '"/> <xsl:value-of select="$current_date" /> [ParlaMint]</title>

                    <title type="sub" xml:lang="en">Report of the meeting of the Dutch <xsl:value-of select="$english_chamber_text"/>, Meeting <xsl:value-of select="$metadata_file/metadata_gegevens/metadata[@name='OVERHEIDop.publicationIssue']/@content"/>, Session <xsl:value-of select="officiele-publicatie/handelingen/agendapunt/nr/text() || ' '" /> <xsl:value-of select="'(' || $current_date || ')'"/> </title>
                    <title type="sub" xml:lang="nl">Verslag van de vergadering van de <xsl:value-of select="$kamer_type"/>, Meeting <xsl:value-of select="$metadata_file/metadata_gegevens/metadata[@name='OVERHEIDop.publicationIssue']/@content"/>, Session <xsl:value-of select="officiele-publicatie/handelingen/agendapunt/nr/text() || ' '" /> <xsl:value-of select="'(' || $current_date || ')'"/> </title>

                    <meeting ana="#parla.meeting.regular">
                        <xsl:attribute name="corresp" select="$chamber_ref" />
                        <xsl:attribute name="n"  select="$metadata_file/metadata_gegevens/metadata[@name='OVERHEIDop.publicationIssue']/@content"/>Meeting <xsl:value-of select="$metadata_file/metadata_gegevens/metadata[@name='OVERHEIDop.publicationIssue']/@content"/>
                    </meeting>

                    <meeting ana="#parla.session">
                        <xsl:attribute name="corresp" select="$chamber_ref" />
                        <xsl:attribute name="n" select="officiele-publicatie/handelingen/agendapunt/nr/text()" />Session <xsl:value-of select="officiele-publicatie/handelingen/agendapunt/nr/text()" /></meeting>

                    <meeting ana="#parla.term">
                        <xsl:attribute name="ana" select = "'#' || 'parla.term' || ' ' || $chamber_ref_num" />
                        <xsl:attribute name="corresp" select="$chamber_ref" />
                        <xsl:attribute name="n" select="$chamber_number"/>Meeting of the <xsl:value-of select="tokenize($chamber_number, '-')[1] || 'th ' || $kamer_type" /></meeting>

                    <respStmt>
                        <persName>Ruben van Heusden</persName>
                        <resp xml:lang="en">Downloading and converting the corpus to TEI format</resp>
                    </respStmt>
                    <funder>
                        <orgName xml:lang="en">The CLARIN research infrastructure</orgName>
                    </funder>
                 </titleStmt>
                    <editionStmt>
                        <edition>2.0</edition>
                    </editionStmt>
                    <!-- The extent tag is used to describe the approximate size of the text
                        (maybe I can add something about the Mb/Gb size here as well)-->
                    <extent>
                        <measure unit="speeches" xml:lang="nl">
                            <xsl:attribute name="quantity">
                                <xsl:number value="$number_of_speeches" />
                            </xsl:attribute>
                            <xsl:number value="$number_of_speeches" /> toespraken</measure>

                        <measure unit="speeches" xml:lang="en">
                            <xsl:attribute name="quantity">
                                <xsl:number value="$number_of_speeches" />
                            </xsl:attribute>
                            <xsl:number value="$number_of_speeches" /> speeches</measure>

                        <measure unit="words" xml:lang="nl">
                            <xsl:attribute name="quantity">
                                <xsl:number value="$number_of_words"/>
                            </xsl:attribute>
                            <xsl:number value="$number_of_words"/> woorden</measure>
                        <measure unit="words" xml:lang="en">
                            <xsl:attribute name="quantity">
                                <xsl:number value="$number_of_words"/>
                            </xsl:attribute>
                            <xsl:number value="$number_of_words"/> words</measure>
                    </extent>
                    <!-- Information regarding the publication of the corpus -->
                    <publicationStmt>
                        <publisher>
                            <orgName xml:lang="en">CLARIN research infrastructure</orgName>
                            <ref target="https://www.clarin.eu/">www.clarin.eu</ref>
                        </publisher>
                        <!-- Identifier of the copus -->
                        <idno type="handle">http://hdl.handle.net/11356/1388</idno>
                        <availability status="free">
                            <licence>http://creativecommons.org/licenses/by/4.0/</licence>
                            <p xml:lang="en">This work is licensed under the<ref target="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</ref>.</p>
                        </availability>
                        <date when="2021-02-01">2021-02-01</date>
                    </publicationStmt>

                    <sourceDesc>
                        <bibl>
                            <title type="main">Minutes of the <xsl:value-of select="$kamer_type"/> of The Netherlands</title>
                            <idno type="URI"> <xsl:value-of select="
                                if ($kamer_type = 'Eerste Kamer') then 'https://www.eerstekamer.nl/' else 'https://www.tweedekamer.nl/'
                                "/></idno>
                        <date>
                                <xsl:attribute name="when" select="$current_date" />
                                <xsl:value-of select="$current_date"/>
                        </date>
                        </bibl>
                    </sourceDesc>
            </fileDesc>
            <encodingDesc>
                <projectDesc>
                    <p xml:lang="en">
                        <ref target="https://www.clarin.eu/content/parlamint">ParlaMint</ref>
                    </p>
                </projectDesc>
                <tagsDecl>
                    <namespace name="http://www.tei-c.org/ns/1.0">
                        <tagUsage gi="body" occurs="1"/>
                        <tagUsage gi="desc" occurs="0"/>
                        <tagUsage gi="div" occurs="1"/>
                        <tagUsage gi="kinesic" occurs="0"/>

                        <!-- Count the number of speeches in the document -->
                        <tagUsage gi="seg">
                            <xsl:attribute name="occurs">
                                <xsl:number value="count(officiele-publicatie/handelingen/agendapunt/spreekbeurt/tekst/al-groep/al)" />
                            </xsl:attribute>
                        </tagUsage>

                        <tagUsage gi="text" occurs="1" />

                        <!-- Count the number of utterances in the document -->
                        <tagUsage gi="u">
                        <xsl:attribute name="occurs">
                            <xsl:number value="$number_of_speeches" />
                        </xsl:attribute>
                        </tagUsage>

                        <tagUsage gi="vocal" occurs="0"/>
                    </namespace>
                </tagsDecl>
            </encodingDesc>
            <profileDesc>
                <settingDesc>
                    <setting>
                        <name type="address">Binnenhof</name>
                        <name type="city">Den Haag</name>
                        <name key="NL" type="country">The Netherlands</name>
                        <date>
                            <xsl:attribute name="when" select="$current_date" />
                            <xsl:value-of select="$current_date" />
                        </date>
                    </setting>
                </settingDesc>
            </profileDesc>
        </teiHeader>

        <text>
            <xsl:attribute name="ana" select="if ($current_date >= xs:date('2019-10-01')) then '#covid' else '#reference'"  />

            <!-- This part of the XSLT script takes care of the conversion of the actual text inside of the original documents-->
           <xsl:attribute name="xml:lang" select="'nl'"/>
            <body>
                <div type="debateSection">
                    <!-- Apply all the templates in the correct order -->
                    <xsl:apply-templates />
                </div>


            </body>
        </text>
        </TEI>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>This template handels 'spreekbeurt' elements that contains the speech elements of the documents.</xd:p>
            <xd:p>It retrieves the information from the speaker from the text and matches it to an appropriate speaker ID (if present).</xd:p>
            <xd:p>It also automatically sets the role of the speaker and if the speaker is a chair it uses the date of the document to inform who the chair is.</xd:p>
            <xd:p>After these processing steps it calls 'apply-templates' again to apply all the subtemplates for the 'spreekbeurt' element.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="officiele-publicatie/handelingen/*/spreekbeurt">
        <xsl:element name="u" xmlns="http://www.tei-c.org/ns/1.0">

            <!-- Retrieve the name of the speaker -->


            <xsl:attribute name="who">
                <xsl:value-of select = "if(contains(lower-case(spreker/naam/achternaam), 'voorzitter')) then $voorzitter_id else concat(string-join(tokenize(spreker/voorvoegsels, ' ')), ' ' , string-join(tokenize(spreker/naam/achternaam, ' '), ' '), '_', string-join(tokenize(spreker/politiek, ' ')))"/>
            </xsl:attribute>
            <!-- Determine whether the speaker is a chair or a regular (or a guest) -->

            <xsl:attribute name="ana">
                <xsl:value-of select="if(contains(lower-case(spreker/naam/achternaam), 'voorzitter')) then '#chair' else (if(spreker/politiek) then '#regular' else '#guest')"/>
            </xsl:attribute>

            <!-- Add the correct number of the utterance to the information -->
            <xsl:attribute name="xml:id">
                <xsl:value-of select="$id || '.u'" />
                <xsl:number count="officiele-publicatie//spreekbeurt" />
            </xsl:attribute>

            <!-- Add the number and the contents of the utterances to the converted document -->
            <xsl:apply-templates select="node() except descendant::motie-info"/>
            <xsl:if test="descendant::motie-info">
                <xsl:apply-templates select="node()//motie-info" />
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>This template takes care of all the 'al' elements in the text, these would correspond to 'seg' tags in the TEI format. </xd:p>
            <xd:p>The expression matches more broadly than just 'spreekbeurt' tags to also include transcriber notes that are note enclosed by those tags. </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="officiele-publicatie//tekst/al-groep/al">
        <xsl:choose>
            <xsl:when test="ancestor::spreekbeurt">
                <seg xmlns="http://www.tei-c.org/ns/1.0">
                    <xsl:attribute name="xml:id">
                        <xsl:value-of select="$id || '.seq'" />
                        <xsl:number count="officiele-publicatie//al" level="any"/>
                    </xsl:attribute>
                    <xsl:value-of select="text()"/>
                </seg>
            </xsl:when>
            <xsl:otherwise>
                <note xmlns="http://www.tei-c.org/ns/1.0">
                    <xsl:value-of select="text()"/>
                </note>

            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>This template is used to match any 'motie' elements or motions in the text and hand them to subtemplates to deal with them accordingly.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match = 'officiele-publicatie/handelingen/agendapunt//tekst/motie'>
            <xsl:apply-templates select="node() except child::motie-info"/>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>This template handles the way the 'motie-info' tag is processed. In this case, a note element is created with a
            document handle in the note, so that there is the possibility to look up this document later if wanted.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match = 'officiele-publicatie/handelingen/agendapunt//tekst/motie/motie-info'>

            <!-- Add the number and the contents of the utterances to the converted document -->
            <xsl:for-each select="for $i in al return $i">
                <note xmlns="http://www.tei-c.org/ns/1.0">
                    <xsl:value-of select="if (position() != last()) then text() else concat('Zij krijgt nr. ', (extref/@doc)[1] )"/>
                </note>
            </xsl:for-each>


    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>This template takes care of any 'lijst' element that is directly inside the 'motie' element and transforms them into notes.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="officiele-publicatie/handelingen/agendapunt//tekst/motie/lijst">
        <xsl:for-each select="for $i in li/al return $i">
            <note xmlns="http://www.tei-c.org/ns/1.0"><xsl:value-of select="."/></note>
        </xsl:for-each>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>This template takes care of any 'al' element that is directly inside the 'motie' element and transforms them into notes.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="officiele-publicatie/handelingen/agendapunt//tekst/motie/al">
        <xsl:for-each select="for $i in . return $i">
            <note xmlns="http://www.tei-c.org/ns/1.0">
                <xsl:value-of select="text()"/>
            </note>
        </xsl:for-each>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>This template takes care of the 'titel' element of a motion by transforming it into a note element.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match = 'officiele-publicatie/handelingen/agendapunt//tekst/motie/kop/titel'>
        <note xmlns="http://www.tei-c.org/ns/1.0"> <xsl:value-of select="."/></note>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>Remove the spreaker element from the text as it is already processed separately in another template.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="officiele-publicatie/handelingen/*/spreekbeurt/spreker" />

    <xd:doc>
        <xd:desc>
            <xd:p>Skip processing of the 'nr' tag of the document as this is already extracted and used in another template.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="officiele-publicatie//nr" />


    <xd:doc>
        <xd:desc>
            <xd:p> Display any titles of items as notes in the original text</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="officiele-publicatie//item-titel">
        <note xmlns="http://www.tei-c.org/ns/1.0"><xsl:value-of select="."/></note>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>Template that skips the item title tag, there might be a better way to handle this information</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="officiele-publicatie//onderwerp" />

    <xsl:template match="officiele-publicatie//handeling_bijlage[@soort = 'stukkenlijst']">
        <note> Lijst van Stukken Bijlagen</note>

    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>This template is used to ignore contents of the vergadering tag as they are redundant and already present in the metadata files.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="officiele-publicatie//vergadering" />

    <xd:doc>
        <xd:desc>
            <xd:p> This template defines what to do with 'lijst' elements that occur with speaker turns, in this case they should also be turned into 'seg' elements</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match = 'officiele-publicatie/handelingen/*/spreekbeurt/tekst/al-groep/lijst'>
        <xsl:for-each select="for $i in li/al return $i">
            <seg xmlns="http://www.tei-c.org/ns/1.0">
                <xsl:attribute name="xml:id">
                    <xsl:value-of select="$id ||'.seq'" />
                    <xsl:number count="officiele-publicatie//al" level="any"/>
                </xsl:attribute>
                <xsl:value-of select="text()"/>
            </seg>
        </xsl:for-each>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>Any lijst that is found outside of a 'spreekbeurt' element is not considered part of the speeches and is transcribed as a note</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match = 'officiele-publicatie/handelingen/*/tekst/al-groep/lijst'>
        <xsl:for-each select="for $i in li/al return $i">
            <note xmlns="http://www.tei-c.org/ns/1.0">
                <xsl:attribute name="xml:id">
                    <xsl:value-of select="$id || '.seq'" />
                    <xsl:number count="officiele-publicatie//al" level="any"/>
                </xsl:attribute>
                <xsl:value-of select="text()"/>
            </note>
        </xsl:for-each>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>Any text that is in a 'spreekbeurt' tag contains a speech that should be encoded with a 'seq' element</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="officiele-publicatie//spreekbeurt/tekst/al">
                <seg xmlns="http://www.tei-c.org/ns/1.0">
                    <xsl:attribute name="xml:id">
                        <xsl:value-of select="$id || '.seq'" />
                        <xsl:number count="officiele-publicatie//al" level="any"/>
                    </xsl:attribute>
                    <xsl:value-of select="text()"/>
                </seg>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>Any text that is directly an the root tag of a document is a transcriber note and is encoded with a note tag</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="officiele-publicatie/handelingen/*/tekst/al">
        <xsl:choose>
            <xsl:when test="contains(lower-case(string-join(text())),'applaus')">
                <kinesic who="#parla.bi">
                    <desc xml:lang="en">Applause</desc>
                </kinesic>
            </xsl:when>
            <xsl:otherwise>
                <note xmlns="http://www.tei-c.org/ns/1.0">
                    <xsl:value-of select="text()"/>
                </note>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>Any occurence of the 'tussenkop' should be ignored, as it contains no useful information for the transformation</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="officiele-publicatie/handelingen/*/tussenkop" />
</xsl:stylesheet>
