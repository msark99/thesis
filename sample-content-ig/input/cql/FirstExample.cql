library FirstExample version '0.1.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1'

codesystem "SNOWMED": 'http://snomed.info/sct'
codesystem "LOINC": 'http://loinc.org'
codesystem "ICD-10": 'http://hl7.org/fhir/sid/icd-10'

valueset "Marital Status": 'http://hl7.org/fhir/ValueSet/marital-status'
//valueset "Condition Clinical Status": 'http://hl7.org/fhir/ValueSet/condition-clinical'
valueset "Condition Clinical Status": 'http://utah.edu/fhir/lcs-cds/ValueSet/conditionclinical'

code "HIV": 'B20' from "ICD-10"
code "HIV NOS": 'Z21' from "ICD-10"
code "ART": '47248-0' from "LOINC"
code "Viral suppression" : '20447-9' from "LOINC"

// abbreviation chapter; nach table of contents?
// neue chapter: passt der inhalt? wieviele seiten gesamt? 10?
// aufteilung insgesamt 10/10/10 introduction & background, design & impl, & architec, evaluation & conclusion & discussion
// synthea?
// Interval hard codiert aktuell
// VALUE SET?????????
// FHIR HELPER VERSION??????
// ist effectivedatetime das richtige kriterium? oder lieber etwas wie G0402 follow up visit for a medicare...
// 1. parameter..
// 3. parameter denom?
// pro parameter, eigene library/cql file? alternative mehrere outputparameter denom1 num1, denom2...
// wie funktioniert das technisch?

//TODO
// deceased : false for minimum data
// outpatient visit

//library, parameter DT
// input measurement parameter
// statistik austria, wie wird aktuell erfasst wv patienten positiv sind
// measure, library anschauen, input output parameter definieren

parameter "Measurement Period" default Interval[@1970-01-01T00:00:00.000, @2023-10-27T00:00:00.000]

context Patient

// 95% that live with HIV will have been tested and know their status
// Numerator:
//    Patients, regardless of age
//    Diagnosis of HIV/AIDS (ICD-10): B20, Z21
//    Received HIV Testing Services (HTS) and their first test result

//    are alive?
//    viral load > 200?
// Denominator: 
//    none

// 95% diagnosed, receive sustained art
// Numerator:
//    Patients, regardless of age
//    Diagnosis of HIV/AIDS (ICD-10): B20, Z21
//    Patient Observation, receives ART (LOINC): 47248-0
//    Patient Encounter during the performance period (CPT or HCPCS): 99201, 99202, 99203, 99204, 99205, 99212, 99213, 99214, 99215, G0402 
//    are alive?
// Denominator: 
//     number of people aged 15-65 living with HIV (positive Diagnosis)

// 95% diagnosed, receive sustained art and achieve viral suppresions
// Numerator: 
//    Patients, regardless of age
//    Diagnosis of HIV/AIDS (ICD-10): B20, Z21
//    Patient Observation, receives art (LOINC): 47248-0
//    Patient Observation, achieve Viralsuppression
//    are alive?
//    
//    Patient Encounter during the performance period (CPT or HCPCS): 99201, 99202, 99203, 99204, 99205, 99212, 99213, 99214, 99215, G0402 
// Denominator: 
//     Number of Patients with a HIV viral load less than 200 copies/mililiter at last viral load test

define "Initial Population":
  Denominator

define Numerator:
  "Receive sustained ART"

define Denominator:
  Patient15To65 and "HIV diagnosis"

define "Patient15To65":
  exists(
    [Patient] p
    where CalculateAgeInYears(p.birthDate.value) >= 15 or CalculateAgeInYears(p.birthDate.value) <= 65
  )

// 95% diagnosed receive sustained art
define "Receive sustained ART":
  "HIV diagnosis" and "Receive ART" and "Recent ART Observation" 

// 95% diagnosed who receive sustained art, receive viral suppressions
define "Receive sustained Viral suppression":
  "HIV diagnosis" and "Receive ART" and "Achieve Viral suppression" and "Recent Viral suppression Observation"

define "HIV diagnosis":
  exists(
    [Condition: "HIV"] H
    where H.clinicalStatus in "Condition Clinical Status"
  )
  or exists(
    [Condition: "HIV NOS"] HNOS
    where HNOS.clinicalStatus in "Condition Clinical Status"
  )

define "Receive ART":
  exists(
    [Observation] ARTValidation
      where "ART".code in ARTValidation.code.coding.code
      and ARTValidation.status in {'final', 'amended', 'corrected'}
  )

define "Achieve Viral suppression":
  exists(
    [Observation] ViralsuppressionValidation
    where "Viral suppression".code in ViralsuppressionValidation.code.coding.code
    and ViralsuppressionValidation.status in {'final', 'amended', 'corrected'}
    and exists(
      [Observation] ViralSuppresionValue
      where ViralSuppresionValue.value.as(Quantity).value < 200
    )
  )

//achieved viral suppression in the last 6 months
define "Recent Viral suppression Observation":
  exists(
    [Observation] RecentObservation
    where date from RecentObservation.effective in Interval[date from end of "Measurement Period" - 6 months, date from end of "Measurement Period"]
  )

// received ART in the last 3 months
define "Recent ART Observation":
  exists(
    [Observation] RecentObservation
    where date from RecentObservation.effective in Interval[date from end of "Measurement Period" - 3 months, date from end of "Measurement Period"]
  )

define "getAge":
  AgeInYears()