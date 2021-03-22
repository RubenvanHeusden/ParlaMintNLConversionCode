# ParlaMintNLConversionCode
Code used for the conversion of the Dutch Parliamentary data to the TEI format for Phase 2 of the ParlaMint Project(https://www.clarin.eu/content/parlamint-call-new-languages).

# Introduction

The code supplied in this repository consists of two XLST conversion scripts that can be used to convert data received from the Officiele Bekendmakingen website (https://zoek.officielebekendmakingen.nl/uitgebreidzoeken/parlementair) to the TEI format. The first script is used to do the main conversion of the documents into the TEI format, whereas the second script is used to correct some of the metadata in the resulting files.

# Requirements

As can be seen in the repository, the current version of the 'conversion.xsl' script relies and a 'voorzitter.xml' file that contains a manually constructed list of the chairs of the two chambers to determine which chair is talking in each of the documents. As this may be cumbersome, this dependency can also be removed from the conversion script, however then the linking between who is chairing a session depending on the type of house and the date will have to be done in some other way, possibly through the use of a Python Script. 

The current version of the 'conversion.xsl' script also requires the metadata file for each document to be present to extract several pieces of metadata, such as the date. The link to this metadata file is in the main file under the 'metadata tag'. (see example below)
```
  <metadata>
    <meta name="OVERHEIDop.externMetadataRecord" scheme="" content="https://zoek.officielebekendmakingen.nl/h-ek-20142015-13-3/metadata.xml" />
  </metadata>
```

As the files were extracted in bulk and the conversion had to be done multiple times for testing, all the metadata files were downloaded and put in a metadata folder, this is why the script relies on there being such a folder now. Of course depending on the XML editor / use-case it might be easier to rewrite this part of the code so that the metadata file is automically retrieved and used together with the source file.

# Additional Points

The current version of the script simply takes the name provided in the source xml document and uses this as an identifier for the person. Although this is a pretty good approach, the files are not always very well maintained when it comes to the names of the actors, and as such there can be several ambiguities in the data as well as some names that are spelled incorrectly. 
