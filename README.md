# Process Mining

An initial patient pathway has been produced and visualised using process mining. This is for discussion with relevant pathway leads and clinical staff. The initial version has been produced for gynae uterine cancer patients but can be amended for any tumour site. The methods are detailed on the output file.

------------------------------------------------------------------------

## Overview

|  |  |
|----|----|
| **Development:** | ![badge](https://img.shields.io/badge/R-blue?logo=r&logoColor=white) ![badge](https://img.shields.io/badge/R%20Studio-blue?logo=rstudioide&logoColor=white) |
| **Sources:** | ![badge](https://img.shields.io/badge/CWT-data-blue?logoColor=white) |
| **Topics:** | ![badge](https://img.shields.io/badge/CWT-blue?logoColor=white) |
| **Output:** | ![badge](https://img.shields.io/badge/HTML-file-blue?logoColor=white&logo=data:image/png;base64,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) ![badge](https://img.shields.io/badge/Static-output-blue?logoColor=white&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAA3NCSVQICAjb4U/gAAAACXBIWXMAAAI0AAACNAFav2WvAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAANtQTFRF////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAhQHXOQAAAEh0Uk5TAAMFBgcJCw4RExUbHSIlKiwvMDEzNUdKS15gYmNncnR7f4eIio+QlJ+jqqust7i6u7/DxMfN0dLb3N/h5efo6vDx9Pn6+/z9cofsFQAAAWFJREFUWMPtlsW2wjAURQMUd3e34u4uhfz/FzG6acpLAmH21soZ3n3OHrQdFCFuopX+bHO9bmb9ShRJJ9jeYSq7dlBq7m3d8FtuLe/3+/wZM3LOfzm3NTEnTds3e/cAczNwf947pliQqeOjQMfC6J/2ZWvfWC4N66Us3sefVLdbTGoIaclilzo+40LB2Gzu0+Y5vTfvY9E+ZfY6Hhp4OiZJCQQL0qq/ozpBC/4+REqrP6/LsSIwxBWUoHJnPKn4HWiJK5hApcqiVaAT3t5OXrmfhf3k47BzBKRxYvOT0I8QSkBhxOYj4AmOIAOFBps3gGc4giwUCmxeAJ7lCHJQyP3GleD/C1y1+eEChcuRGZMf5jWXde9bY8msfRZBT3aPcY/ea4a8wNAoQVh+j3GYEsR+EcSUQAmUQAmUQAk4gsgvggglcD7k9w8nJUBDecGQ3qPAUXZ/DFgEyKdvZeZbHf4vXjuWo+s7dUhkAAAAAElFTkSuQmCC) ![badge](https://img.shields.io/badge/Restricted-audience-blue?logoColor=white&logo=data:image/png;base64,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) |

------------------------------------------------------------------------

## Metadata

### Source Data

- **Dataset Name:** Cancer Waiting Times - Download Patient Records
  - **Owner:** NHS England
  - **Visibility:** Private
  - **URI:** <https://nationaldataintegration.federateddataplatform.nhs.uk/workspace/module/view/latest/ri.workshop.main.module.ff70568e-ef62-4a96-b6d6-f5b17a2eb2b9>

### Access / Information Governance

- **Output type:** Interactive .html file
- **Output location:** WMCA Data Analytics FutureNHS workspace
- **Output URI:** <https://future.nhs.uk/MidlandsCancerAlliancesAnalytics/view?objectId=75239248>
- **Access restrictions:** As per FutureNHS
- **DSA/DARS/etc. in place?** Yes, for CWT

### Target Audience

- **Organisation(s):** WMCA, Provider and commissioner stakeholders
- **Committee(s):** EAGs
- **Job Role(s):** WMCA Pathway Leads, EAG Chairs

### Distribution

- **Method:** FutureNHS
- **Frequency:** Annual

------------------------------------------------------------------------

## Contacts

### Contributor(s)

- **Name:** See Github
- **Organisation:** West Midlands Cancer Alliance

### Owner(s)

- **Organisation:** West Midlands Cancer Alliance (WMCA)
- **Contact:** Data Analytics team
- **Contact Email:** [rwh-tr.wmcadata\@nhs.net](mailto:%5Brwh-tr.wmcadata@nhs.net){.email}

------------------------------------------------------------------------

## Usage

See the `docs` folder.

------------------------------------------------------------------------

## Licence

Copyright © Crown Copyright 2025 (National Health Service)

You may use and re-use this software and associated documentation files free of charge in any format or medium, under the terms of the Open Government Licence v3.0.

You may obtain a copy of the Open Government Licence at <https://www.nationalarchives.gov.uk/doc/open-government-licence/>

![Open Government Licence text logo](assets/logos/ogl.png)
