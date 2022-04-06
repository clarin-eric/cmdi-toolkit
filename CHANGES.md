# 1.2.5
April 2022

- Cues defined on attributes are now properly represented in the profile XSD
(see [#17](https://github.com/clarin-eric/cmdi-toolkit/issues/17))

# 1.2.4
January 2021

- Namespace for cues for tools changed from 
`http://www.clarin.eu/cmdi/cues/1` to `http://www.clarin.eu/cmd/cues/1`
(see [#14](https://github.com/clarin-eric/cmdi-toolkit/issues/14))
- Added Schematron rules for best practices
- Group ID for Maven artifact changed to `eu.clarin.cmdi`

# 1.2.3
November 2019

- Updated Java libraries:
  - SchemAnon 1.0.0 -> 1.1.0
  - cmdi-validator-core 1.0.0 -> 1.2.1
  - jopt-simple 4.8 -> 4.9

# 1.2.2
June 2017

- Fixed some issues related to the creation of vocabulary information in the profile XSDs

# 1.2.1
August 2016

- `Component/Documentation` and `Attribute/Documentation` skipped when downgrading components ([#5](https://github.com/clarin-eric/cmdi-toolkit/issues/5))
- `Header/DerivedFrom` skipped when downgrading components ([#6](https://github.com/clarin-eric/cmdi-toolkit/issues/6))
- Separate build profile for upgrade tool, allowing for a much smaller 'core' JAR file

# 1.2.0
July 2016

Many new features, improvements and other changes. Amongst other things:

- Fields can be associated with external vocabularies (from CLAVAS), providing options for both closed and open controlled vocabularies
- Attributes on elements and components can be made mandatory, whereas they are always optional in CMDI 1.1
- The documentation options for components and profiles have been improved, now allowing for multilingual documentation on all levels
- Each profile has its own XML namespace
- The way in which relations among resources within a CMDI record can be expressed has been improved

For more details and a link to the full specification, see 
[www.clarin.eu/cmdi1.2](https://www.clarin.eu/cmdi1.2).
