<?xml version='1.0' encoding="UTF-8" ?>
<!--
****************************************************************
DITA to XSL-FO Stylesheet
Module: Merged file conversion templates
Copyright © 2009-2013 Antenna House, Inc. All rights reserved.
Antenna House is a trademark of Antenna House, Inc.
URL    : http://www.antennahouse.com/
E-mail : info@antennahouse.com
****************************************************************
-->
<xsl:stylesheet version="2.0" 
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"
 xmlns:ahf="http://www.antennahouse.com/names/XSLT/Functions/Document"
 exclude-result-prefixes="xs ahf"
>
    <!--root-->
    <xsl:variable name="root" as="element()" select="/*[1]"/>
    
    <!-- map or bookmap -->
    <xsl:variable name="map" as="element()" select="/*[1]/*[contains(@class,' map/map ')][1]"/>
    
    <!-- All topiref-->
    <xsl:variable name="allTopicRefs" as="element()*" select="$map//*[contains(@class,' map/topicref ')][not(ancestor::*[contains(@class,' map/reltable ')])]"/>
    
    <!-- topicref that has @print="no"-->
    <xsl:variable name="noPrintTopicRefs" as="element()*" select="$allTopicRefs[ancestor-or-self::*[string(@print) eq 'no']]"/>
    
    <!-- Normal topicref -->
    <xsl:variable name="normalTopicRefs" as="element()*" select="$allTopicRefs except $noPrintTopicRefs"/>
    
    <!-- @href of topicref that has @print="no"-->
    <xsl:variable name="noPrintHrefs" as="xs:string*">
        <xsl:for-each select="$noPrintTopicRefs">
            <xsl:if test="exists(@href)">
                <xsl:sequence select="string(@href)"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:variable>
    
    <!-- @href of noraml topicref -->
    <xsl:variable name="normalHrefs" as="xs:string*">
        <xsl:for-each select="$normalTopicRefs">
            <xsl:if test="exists(@href)">
                <xsl:sequence select="string(@href)"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:variable>

    <!-- topicrefs that references same topic -->
    <xsl:variable name="duplicateTopicRefs" as="element()*">
        <xsl:for-each select="$map//*[contains(@class,' map/topicref ')][exists(@href)][empty(ancestor::*[contains(@class,' map/reltable ')])]">
            <xsl:variable name="topicRef" as="element()" select="."/>
            <xsl:variable name="href" as="xs:string" select="string(@href)"/>
            <xsl:if test="$topicRef/preceding::*[contains(@class,' map/topicref ')][exists(@href)][string(@href) eq $href][empty($noPrintTopicRefs[. is $topicRef])]">
                <xsl:sequence select="$topicRef"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:variable name="hasDupicateTopicRefs" as="xs:boolean" select="exists($duplicateTopicRefs)"/>

    <!-- key -->
    <xsl:key name="topicById"  match="/*//*[contains(@class, ' topic/topic')]" use="@id"/>

    <!-- 
     function:	root element template
     param:		none
     return:	copied result
     note:		
     -->
    <xsl:template match="dita-merge">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
            <xsl:if test="$hasDupicateTopicRefs">
                <xsl:call-template name="outputDuplicateTopic"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <!-- 
     function:	General template for all element
     param:		none
     return:	copied result
     note:		
     -->
    <xsl:template match="*">
        <xsl:param name="prmDitaValFlagStyle" tunnel="yes" required="no" select="''"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="string($prmDitaValFlagStyle)">
                <xsl:copy-of select="ahf:getMergedDitaValFlagStyleAttr(.,$prmDitaValFlagStyle)"/>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <!-- 
     function:	topicgroup
     param:		none
     return:	descendant element
     note:		An topicgroup is redundant for document structure.
                It sometimes bothers counting the nesting level of topicref.
     -->
    <xsl:template match="*[contains(@class, ' mapgroup-d/topicgroup ')]" priority="2">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!--
     function:	topicref
     param:		none
     return:	self and descendant element or none
     note:		if @print="no", ignore it.
     -->
    <xsl:template match="*[contains(@class,' map/topicref ')]">
        <xsl:variable name="topicRef" as="element()" select="."/>
    	<xsl:choose>
    		<xsl:when test="string(@print) eq 'no'" >
    		    <xsl:for-each select="descendant-or-self::*[contains(@class,' map/topicref ')]">
    		        <xsl:if test="exists(@href)">
    		            <xsl:message select="'[convmerged 1001I] Removing topicref. href=',string(@href),' ohref=',string(@ohref)"/>
    		        </xsl:if>
    		    </xsl:for-each>
    		</xsl:when>
    	    <xsl:when test="empty(ancestor::*[contains(@class,' map/reltable ')]) and $duplicateTopicRefs[. is $topicRef]">
    	        <xsl:variable name="href" as="xs:string" select="string(@href)"/>
    	        <xsl:variable name="duplicateCount" as="xs:integer" select="count($topicRef/preceding::*[contains(@class,' map/topicref ')][string(@href) eq $href]) + 1"/>
    	        <xsl:copy>
    	            <xsl:apply-templates select="@*">
    	                <xsl:with-param name="prmTopicRefNo" select="$duplicateCount"/>
    	            </xsl:apply-templates>
    	            <xsl:apply-templates/>
    	        </xsl:copy>
    	    </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="@*">
        <xsl:copy/>
    </xsl:template>
    
    <!-- template for topicref/@href is limited for create new value -->
    <xsl:template match="*[contains(@class,' map/topicref ')]/@href">
        <xsl:param name="prmTopicRefNo" required="yes" as="xs:integer"/>
        <xsl:variable name="href" as="xs:string" select="string(.)"/>
        <xsl:attribute name="href" select="if ($prmTopicRefNo gt 0) then concat($href,'_',string($prmTopicRefNo)) else $href"/>
    </xsl:template>

    <!--
     function:	output duplicate topic changing topic/@id
     param:		none
     return:	self and descendant element 
     note:		
     -->
    <xsl:template name="outputDuplicateTopic">
        <xsl:for-each select="$duplicateTopicRefs">
            <xsl:variable name="topicRef" as="element()" select="."/>
            <xsl:variable name="href" as="xs:string" select="string(@href)"/>
            <xsl:variable name="duplicateCount" as="xs:integer" select="count($topicRef/preceding::*[contains(@class,' map/topicref ')][string(@href) eq $href]) + 1"/>
            <xsl:variable name="topicContent" as="element()?" select="ahf:getTopicFromTopicRef($topicRef)"/>
            <xsl:choose>
                <xsl:when test="empty($topicContent)">
                    <xsl:message select="'[convmerged 1009F] Cannot find topic from topic/@href=',$href"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$topicContent">
                        <xsl:with-param name="prmTopicRefNo" tunnel="yes" select="$duplicateCount"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <!-- 
     function:	Get topic from topicref 
     param:		prmTopicRef
     return:	xs:element?
     note:		
     -->
    <xsl:function name="ahf:getTopicFromTopicRef" as="element()?">
        <xsl:param name="prmTopicRef" as="element()"/>
        <xsl:variable name="id" select="substring-after($prmTopicRef/@href, '#')" as="xs:string"/>
        <xsl:variable name="topicContent" select="if (string($id)) then key('topicById', $id, $root)[1] else ()" as="element()?"/>
        <xsl:sequence select="$topicContent"/>
    </xsl:function>

    <!--
     function:	topicref: @chunk contains 'to-content'
     param:		none
     return:	self only
     note:		if @print="no", ignore it.
                Skip child topicref because they are nested in topic referenced by this topicref/@href.
                2015-09-04 t.makita
                Exclude topicref that has @copy-to attribute.
                2015-09-09 t.makita
     -->
    <xsl:template match="*[contains(@class,' map/topicref ')][ahf:HasAttr(@chunk,'to-content')][empty(@copy-to)]" priority="2">
        <xsl:choose>
            <xsl:when test="@print='no'" >
                <xsl:for-each select="descendant-or-self::*[contains(@class,' map/topicref ')]">
                    <xsl:if test="exists(@href)">
                        <xsl:message select="'[convmerged 1001I] Removing topicref. href=',string(@href),' ohref=',string(@ohref)"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates select="* except *[contains(@class,' map/topicref ')]"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    

    <!--
     function:	topic
     param:		none
     return:	self and descendant element or none
     note:		if @id is pointed from the topicref that has print="no", ignore it.
     -->
    <xsl:template match="*[contains(@class,' topic/topic ')]">
        <xsl:param name="prmDitaValFlagStyle" tunnel="yes" required="no" select="''"/>
        <xsl:param name="prmTopicRefNo" required="no" tunnel="yes" as="xs:integer" select="0"/>

        <xsl:variable name="id" as="xs:string" select="concat('#',string(@id))"/>
        <xsl:choose>
            <xsl:when test="exists(index-of($noPrintHrefs,$id)) and empty(index-of($normalHrefs,$id))">
                <xsl:message select="'[convmerged 1002I] Removing topic. id=',string(@id),' xtrf=',string(@xtrf)"/>
            </xsl:when>
            <xsl:when test="$prmTopicRefNo gt 0">
                <xsl:copy>
                    <xsl:apply-templates select="@*">
                        <xsl:with-param name="prmTopicRefNo" select="$prmTopicRefNo"/>
                    </xsl:apply-templates>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:if test="string($prmDitaValFlagStyle)">
                        <xsl:copy-of select="ahf:getMergedDitaValFlagStyleAttr(.,$prmDitaValFlagStyle)"/>
                    </xsl:if>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- template for topic/@id is limited for create new value -->
    <xsl:template match="*[contains(@class,' topic/topic ')]/@id">
        <xsl:param name="prmTopicRefNo" required="yes" as="xs:integer"/>
        <xsl:variable name="id" as="xs:string" select="string(.)"/>
        <xsl:attribute name="id" select="if ($prmTopicRefNo gt 0) then concat($id,'_',string($prmTopicRefNo)) else $id"/>
    </xsl:template>
    
    <xsl:template match="*[contains(@class,' topic/topic ')]/@oid">
        <xsl:param name="prmTopicRefNo" required="yes" as="xs:integer"/>
        <xsl:variable name="oid" as="xs:string" select="string(.)"/>
        <xsl:attribute name="oid" select="if ($prmTopicRefNo gt 0) then concat($oid,'_',string($prmTopicRefNo)) else $oid"/>
    </xsl:template>
    
    
    <!--
     function:	link
     param:		none
     return:	self and descendant element or none
     note:		if link@href points to the topicref that has print="no", ignore it.
     -->
    <xsl:template match="*[contains(@class,' topic/link ')]">
        <xsl:param name="prmDitaValFlagStyle" tunnel="yes" required="no" select="''"/>
        <xsl:variable name="href" as="xs:string" select="string(@href)"/>
        <xsl:choose>
            <xsl:when test="exists(index-of($noPrintHrefs,$href)) and empty(index-of($normalHrefs,$href))">
                <xsl:message select="'[convmerged 1003I] Removing link. href=',$href"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:if test="string($prmDitaValFlagStyle)">
                        <xsl:copy-of select="ahf:getMergedDitaValFlagStyleAttr(.,$prmDitaValFlagStyle)"/>
                    </xsl:if>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--
     function:	xref
     param:		none
     return:	self and descendant element or none
     note:		if xref@href points to the topic that has print="no", ignore it.
     -->
    <xsl:template match="*[contains(@class,' topic/xref ')]">
        <xsl:param name="prmDitaValFlagStyle" tunnel="yes" required="no" select="''"/>
        <xsl:param name="prmTopicRefNo" required="no" tunnel="yes" as="xs:integer" select="0"/>

        <xsl:variable name="xref" as="element()" select="."/>
        <xsl:variable name="href" as="xs:string" select="string(@href)"/>
        <xsl:variable name="isLocalHref" as="xs:boolean" select="starts-with($href,'#')"/>
        <xsl:variable name="refTopicHref" as="xs:string">
            <xsl:choose>
                <xsl:when test="$isLocalHref">
                    <xsl:choose>
                        <xsl:when test="contains($href,'/')">
                            <xsl:sequence select="substring-before($href,'/')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="$href"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="string($refTopicHref) and exists(index-of($noPrintHrefs,$refTopicHref)) and empty(index-of($normalHrefs,$refTopicHref))" >
            <xsl:message select="'[convmerged 1004W] Warning! Xref refers to removed topic. href=',string(@href)"/>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="$isLocalHref and ($prmTopicRefNo gt 0)">
                <xsl:variable name="refTopicId" as="xs:string" select="substring-after($refTopicHref,'#')"/>
                <xsl:variable name="refElemId" as="xs:string" select="if (contains($href,'/')) then substring-after($href,'/') else ''"/>
                <xsl:variable name="topIds" as="xs:string+" select="for $id in $xref/ancestor::*[contains(@class,' topic/topic ')][last()]/descendant-or-self::*[contains(@class,' topic/topic ')]/@id return string($id)"/>
                <xsl:choose>
                    <xsl:when test="exists($topIds[. eq $refTopicId])">
                        <xsl:copy>
                            <xsl:apply-templates select="@*">
                                <xsl:with-param name="prmNewXrefHref">
                                    <xsl:choose>
                                        <xsl:when test="string($refElemId)">
                                            <xsl:sequence select="concat($refTopicHref,'_',string($prmTopicRefNo),'/',$refElemId)"/>        
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:sequence select="concat($refTopicHref,'_',string($prmTopicRefNo))"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:with-param>
                            </xsl:apply-templates>
                            <xsl:if test="string($prmDitaValFlagStyle)">
                                <xsl:copy-of select="ahf:getMergedDitaValFlagStyleAttr(.,$prmDitaValFlagStyle)"/>
                            </xsl:if>
                            <xsl:apply-templates/>
                        </xsl:copy>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy>
                            <xsl:copy-of select="@*"/>
                            <xsl:if test="string($prmDitaValFlagStyle)">
                                <xsl:copy-of select="ahf:getMergedDitaValFlagStyleAttr(.,$prmDitaValFlagStyle)"/>
                            </xsl:if>
                            <xsl:apply-templates/>
                        </xsl:copy>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:if test="string($prmDitaValFlagStyle)">
                        <xsl:copy-of select="ahf:getMergedDitaValFlagStyleAttr(.,$prmDitaValFlagStyle)"/>
                    </xsl:if>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="*[contains(@class,' topic/xref ')]/@href">
        <xsl:param name="prmNewXrefHref" required="yes" as="xs:string"/>
        <xsl:attribute name="href" select="$prmNewXrefHref"/>
    </xsl:template>
    
    <!-- 
     function:	comment template
     param:		none
     return:	comment 
     note:		none
     -->
    <xsl:template match="comment()">
        <xsl:copy/>
    </xsl:template>
    
    <!-- 
     function:	processing-instruction template
     param:		nome
     return:	processing-instruction
     note:		
     -->
    <xsl:template match="processing-instruction()">
        <xsl:copy/>
    </xsl:template>

    <!-- 
     function:	required-cleanup template
     param:		none
     return:	none or itself 
     note:		If not output required-cleanup, remove it at this template.
     -->
    <xsl:template match="*[contains(@class,' topic/required-cleanup ')][not($pOutputRequiredCleanup)]"/>
    
    <!-- 
     function:	draft-comment template
     param:		none
     return:	none or itself 
     note:		If not output draft-comment, remove it at this template.
     -->
    <xsl:template match="*[contains(@class,' topic/draft-comment ')][not($pOutputDraftComment)]"/>
	
    <!-- 
     function:	Check $prmAttr has $prmValue
     param:		prmAttr, prmValue
     return:	xs:boolean 
     note:		Return true() if $prmAttr attribute has $prmValue
     -->
    <xsl:function name="ahf:HasAttr" as="xs:boolean">
        <xsl:param name="prmAttr" as="attribute()?"/>
        <xsl:param name="prmValue" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="empty($prmAttr)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="attr" as="xs:string" select="string($prmAttr)"/>
                <xsl:variable name="attVals" as="xs:string*" select="tokenize($attr,'[\s]+')"/>
                <xsl:sequence select="$prmValue = $attVals"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>
