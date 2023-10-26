library FirstExample version '0.1.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.3.000'

codesystem "SNOWMED": 'http://snomed.info/sct'
codesystem "LOINC": 'http://loinc.org'
codesystem "ICD-10": 'http://hl7.org/fhir/sid/icd-10'

valueset "Marital Status": 'http://hl7.org/fhir/ValueSet/marital-status'
valueset "Condition Clinical Status": 'http://utah.edu/fhir/lcs-cds/ValueSet/conditionclinical'

// HIV Test results
//code "HIV Negative": '165815009' from "SNOMED-CT" display 'HIV Negative'
//code "HIV Positive": '165816005' from "SNOMED-CT" display 'HIV Positive'

code "HIV": 'B20' from "ICD-10"
// namen ändern
code "Receive Art": '47248-0' from "LOINC"

//output parameter deinieren numerator/denominator
// cql -> base64
//library, parameter DT
// input measurement parameter
// statistik austria, wie wirkt aktuell erfasst wv patienten positiv sind

// measure, library anschauen, input output parameter definieren, herausfinden was mit 64code machen muss und dann evaluieren

context Patient

define "Denominator1":
  "HIV diagnosis"
// 95% know their status

// 95% diagnosed, receive ART

// 95% diagnosed, receive ART and viral suppresions

define "HIV diagnosis":
  [Condition: "HIV"] H
    where H.clinicalStatus in "Condition Clinical Status"

define "Receive ART":
  exists(
    [Observation] ARTValidation
      where "Receive Art".code in ARTValidation.code.coding.code
      and ARTValidation.status in {'final', 'amended', 'corrected'}
  )

define PatientExample:
  Patient P
    where P.gender = 'male'
      and P.active is true
      and P.birthDate 30 years or more before Today()
      and not(P.deceased)
      and P.maritalStatus in "Marital Status"

define "Get all Condition Codes":
   [Condition] C
   return FHIRHelpers.ToCode(singleton from C.code.coding)
