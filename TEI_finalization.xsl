<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ns="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="xs math xd"
    version="3.0">
    
    <xsl:variable name="num_body" select="count(ns:TEI//ns:body)"/>
    <xsl:variable name="num_desc" select="count(ns:TEI//ns:desc)"/>
    <xsl:variable name="num_div" select="count(ns:TEI//ns:div)"/>
    <xsl:variable name="num_kinesic" select="count(ns:TEI//ns:kinesic)"/>
    <xsl:variable name="num_seg" select="count(ns:TEI//ns:seg)"/>
    <xsl:variable name="num_text" select="count(ns:TEI//ns:text)"/>
    <xsl:variable name="num_u" select="count(ns:TEI//ns:u)"/>
    <xsl:variable name="num_vocal" select="count(ns:TEI//ns:vocal)"/>
    <xsl:variable name="num_words" select = "count(ns:TEI//ns:seg/text()/tokenize(normalize-space(.),'\s'))"/>
    <xsl:variable name="num_notes" select="count(ns:TEI//ns:note)"/>
    
    
    <xsl:output method="xml" indent="yes"/>   
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ns:u">
        <xsl:element name = "note" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="type">speaker</xsl:attribute>
            <xsl:value-of select="current()/@who" />
        </xsl:element>
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ns:namespace">
        <xsl:element name="namespace" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="name" select="'http://www.tei-c.org/ns/1.0'" />
            
            <xsl:element name="tagUsage" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="gi" select="'body'" />
                <xsl:attribute name="occurs" select="$num_body"/>
            </xsl:element>
            
            <xsl:element name="tagUsage" namespace="http://www.tei-c.org/ns/1.0">
                <xsl:attribute name="gi" select="'div'" />
                <xsl:attribute name="occurs" select="$num_div"/>
            </xsl:element>
            
            <xsl:element name="tagUsage" namespace="http://www.tei-c.org/ns/1.0">
                <xsl:attribute name="gi" select="'seg'" />
                <xsl:attribute name="occurs" select="$num_seg"/>
            </xsl:element>
            
            <xsl:element name="tagUsage" namespace="http://www.tei-c.org/ns/1.0">
                <xsl:attribute name="gi" select="'text'" />
                <xsl:attribute name="occurs" select="$num_text"/>
            </xsl:element>
            
            <xsl:element name="tagUsage" namespace="http://www.tei-c.org/ns/1.0">
                <xsl:attribute name="gi" select="'u'" />
                <xsl:attribute name="occurs" select="$num_u"/>
            </xsl:element>
            
            <xsl:element name="tagUsage" namespace="http://www.tei-c.org/ns/1.0">
                <xsl:attribute name="gi" select="'note'" />
                <xsl:attribute name="occurs" select="$num_notes"/>
            </xsl:element>
            
        </xsl:element>
    </xsl:template>       
    
    
    <xsl:template match="ns:extent">
        <xsl:element name="extent" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:element name="measure" namespace="http://www.tei-c.org/ns/1.0">
                <xsl:attribute name="unit" select="'speeches'" />
                <xsl:attribute name="xml:lang" select="'nl'" />
                <xsl:attribute name="quantity">
                    <xsl:number value="$num_u" />
                </xsl:attribute>
                <xsl:number value="$num_u" /> toespraken</xsl:element>
            
            <xsl:element name="measure" namespace="http://www.tei-c.org/ns/1.0">
                <xsl:attribute name="unit" select="'speeches'" />
                <xsl:attribute name="xml:lang" select="'en'" />
                <xsl:attribute name="quantity">
                    <xsl:number value="$num_u" />
                </xsl:attribute>
                <xsl:number value="$num_u" /> speeches</xsl:element>
            
            <xsl:element name="measure" namespace="http://www.tei-c.org/ns/1.0">
                <xsl:attribute name="unit" select="'words'" />
                <xsl:attribute name="xml:lang" select="'nl'" />
                <xsl:attribute name="quantity">
                    <xsl:number value="$num_words" />
                </xsl:attribute>
                <xsl:number value="$num_words" /> woorden</xsl:element>
            
            
            <xsl:element name="measure" namespace="http://www.tei-c.org/ns/1.0">
                <xsl:attribute name="unit" select="'words'" />
                <xsl:attribute name="xml:lang" select="'en'" />
                <xsl:attribute name="quantity">
                    <xsl:number value="$num_words" />
                </xsl:attribute>
                <xsl:number value="$num_words" /> words</xsl:element>
            </xsl:element>
    </xsl:template>
    
    <xsl:template match="ns:u/@xml:id">  
        <xsl:attribute name="xml:id">
            <xsl:value-of select="tokenize(current(),'\.')[1] || '.u' "/>
            <xsl:number count="ns:u" level="any"/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="ns:seg/@xml:id">  
        <xsl:attribute name="xml:id">
            <xsl:value-of select="tokenize(current(),'\.')[1] ||  '.seg'"/>
            <xsl:number count="ns:seg" level="any"/>
        </xsl:attribute>
    </xsl:template>
</xsl:stylesheet>