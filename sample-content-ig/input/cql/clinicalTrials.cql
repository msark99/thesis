library clinicalTrials version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.3.000' called FHIRHelpers


valueset "Tobacco Codes": 'http://hl7.org/fhir/ValueSet/tobacco-use'
//possibly select these codes in UI

valueset "exclusionValueset": 'http://hl7.org/fhir/ValueSet/tobacco-use'

codesystem "LOINC": 'http://loinc.org'
code "Pregnant": 'LA15173-0' from "LOINC" display 'Pregnant'
code "Pregnancy Observation": '82810-3' from "LOINC" display 'Pregnancy Status'


parameter "InclusionConditionCode" Code default Code {
  code: 'J45.909',
  display: 'Asthma, unspecified, uncomplicated',
  system: 'http://hl7.org/fhir/sid/icd-10'
}
parameter "InclusionConditionCodes" List<Code> default List<Code> {
  Code{code: 'J45.909',
  display: 'Asthma, unspecified, uncomplicated',
  system: 'http://hl7.org/fhir/sid/icd-10'
  }
}
parameter "InclusionConditionEvaluation" Boolean default true

parameter "ExclusionConditionCodes" List<Code> default List<Code> {
   Code{code: '372137005',
	  display: 'Primary malignant neoplasm of breast',
    system: 'http://snomed.info/sct'
   }
}
  


parameter "ExclusionConditionEvaluation" Boolean default true

parameter "ageEvaluation" Boolean default true
parameter "DefinedAgeRange" Interval<Integer> default Interval[1,100]

parameter "genderEvaluation" Boolean default true
parameter "DefinedGenderCode" Code default Code {
  code: 'female',
  display: 'Female',
  system: 'http://hl7.org/fhir/administrative-gender'
}

parameter "pregnancyEvaluation" Boolean default true
parameter "DefinedCurrentPregnancyValue" Boolean default true

parameter "tobacooEvaluation" Boolean default true
parameter "DefinedCurrentTobaccoUse" Boolean default false


parameter "Measurement Period" default Interval[@1923-01-01T00:00:00.000, @2023-09-16T00:00:00.000]



context Patient

define "Inclusion Criteria":
    (if ageEvaluation is true then
    "Age Criteria"
    else 
      true)//ignore this criteria
    and
    (if genderEvaluation is true then
     "Gender Criteria"
    else 
      true)//ignore this criteria
    and
    (if InclusionConditionEvaluation is true then
     "Preexisting Conditions"(InclusionConditionCodes)
    else 
      true)//ignore this criteria
    and
    (if pregnancyEvaluation is true  and Patient.gender = 'female ' then
      DefinedCurrentPregnancyValue= "Current Pregnancy" 
    else
      true)//ignore this criteria
    and 
    (if tobacooEvaluation is true then
       DefinedCurrentTobaccoUse = "Current Tobacco Use"
      else
      true)//ignore this criteria
    

define "Fulfills Clinical Trial Criteria":
    "Inclusion Criteria"
    and not "Exclusion Criteria"


define "Exclusion Criteria":
    if ExclusionConditionEvaluation is true then
     "Preexisting Conditions"(ExclusionConditionCodes)
     else
      true


define "getAge":
 AgeInYears()

define "Age Criteria":
    
  AgeInYears() in DefinedAgeRange
   

define "Get all Condition Codes":
   [Condition] C
   return FHIRHelpers.ToCode(singleton from C.code.coding)
  

//todo for now only checks if the patient has one condition
define function "Preexisting Conditions"(ConditionCodes List<Code>):
  Length(ConditionCodes intersect "Get all Condition Codes") = Length(ConditionCodes)
      //and 
      //ConditionCode.system in ConditionValidation.code.coding.system 
      
define "Condition codings":
  Conditions C return C.code.coding


define "debuggingConditionCodeslength":
  Length(InclusionConditionCodes.code)

define "debuggingConditions":
  Conditions.code.coding.code

define "debugging Intersect":
  InclusionConditionCodes intersect "Get all Condition Codes"
      
define "Gender Criteria":
  Patient.gender = DefinedGenderCode.code
    

define "Current Pregnancy":
  exists(
  [Observation] PregnancyValidation
    where "Pregnancy Observation".code in PregnancyValidation.code.coding.code
    and PregnancyValidation.status in { 'final', 'amended', 'corrected' }
    and Pregnant.code in PregnancyValidation.value.coding.code
    and date from PregnancyValidation.effective in Interval[date from end of "Measurement Period"- 9 months, date from end of "Measurement Period"]  
  )

 define "Observations":
  ["Observation"]

  define "Conditions":
    [Condition]

  define "Current Tobacco Use":
  exists(
    [Observation] TobaccoUse 
    where TobaccoUse.value.coding in "Tobacco Codes"
  )