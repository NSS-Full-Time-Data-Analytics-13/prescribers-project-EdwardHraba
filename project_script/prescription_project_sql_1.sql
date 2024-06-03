--	1. 
--    a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT SUM(total_claim_count) AS claims, npi 
FROM prescription
WHERE total_claim_count IS NOT NULL
GROUP BY npi
ORDER BY claims DESC;
												--ANSWER) npi- 1881634483 total claims- 99707--


--    b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT SUM(total_claim_count) AS claims,nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description
FROM prescription
 	FULL JOIN prescriber USING (npi)
WHERE total_claim_count IS NOT NULL
GROUP BY nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description
ORDER BY claims DESC;
												--ANSWER:Bruce Pendley 99707 family prescription--




--2. 
--    a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description,
	SUM (total_claim_count) AS total_claims
FROM prescriber
	FULL JOIN prescription USING (npi)
WHERE total_claim_count IS NOT NULL
GROUP BY specialty_description
ORDER BY total_claims DESC;
														--ANSWER:FAMILY PRACTICE 9752347--




--    b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description,
	SUM(total_claim_count) AS number_of_claims
FROM prescriber
	FULL JOIN prescription USING (npi)
	FULL JOIN drug USING (drug_name)
WHERE opioid_drug_flag ILIKE 'Y'
	AND total_claim_count IS NOT NULL
GROUP BY specialty_description
ORDER BY number_of_claims DESC;
													--ANSWER:Nurse Practitioner 900845--

--  c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT specialty_description, prescription.total_claim_count
FROM prescriber
	FULL JOIN prescription USING (npi)
WHERE prescription.total_claim_count IS NULL
GROUP BY specialty_description, prescription.total_claim_count;

																--ANSWER:92--

--  							d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* 
--For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
 




--3. 
--   a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name, MAX(total_drug_cost)::money AS highest_total_drug
FROM prescription 
	FULL JOIN drug USING (drug_name)
WHERE total_drug_cost IS NOT NULL
GROUP BY generic_name
ORDER BY highest_total_drug DESC;
														--ANSWER:PIRFENIDONE $2,829,174.30--





--   b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT  *
FROM prescription
	FULL JOIN drug USING(drug_name);

SELECT  DISTINCT generic_name, ROUND(max(total_drug_cost/365),2)::money AS cost_per_day
FROM prescription
	INNER JOIN drug USING(drug_name)
WHERE total_drug_cost IS NOT NULL
GROUP BY generic_name
ORDER BY cost_per_day DESC;
															--ANSWER:Pirfenidone $7,751.16--

--4
  --  a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT drug_name,
	CASE WHEN opioid_drug_flag ILIKE 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag ILIKE 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS drug_type
FROM drug;

  --  b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT SUM(total_drug_cost)::money AS total_spent,
	CASE WHEN opioid_drug_flag ILIKE 'Y' THEN 'Opioids'
		 WHEN antibiotic_drug_flag ILIKE 'Y' THEN 'Antibiotics'
		 ELSE 'neither' END AS drug_type
FROM drug
	JOIN prescription USING (drug_name) 
WHERE opioid_drug_flag = 'Y' 
	OR antibiotic_drug_flag ILIKE 'Y'
GROUP BY drug_type,opioid_drug_flag,antibiotic_drug_flag;
															--ANSWER:Opioids at $105,080,626.37--


--5. 
   -- a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.


SELECT COUNT(DISTINCT cbsa)
FROM cbsa
	JOIN fips_county USING (fipscounty)
WHERE state ILIKE 'TN';

															--ANSWER: 10--

   -- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

(SELECT cbsaname, SUM(population) AS total_pop, 'largest' AS size	-- make a new column named size that will have a row that says largest exclusivly
FROM cbsa															-- this will pull the highest total pop by using desc and you limit it to only 1 
	JOIN population USING (fipscounty)								-- to only show that highest one
	GROUP BY cbsaname
	ORDER BY total_pop DESC
	limit 1)														-- JOIN THESE TWO TOGETHER TO SEE THE HGIHEST AND LOWEST USING A UNION
UNION 					
(SELECT cbsaname, SUM(population) AS total_pop, 'smallest' AS size	-- make a new column named size that will have a row that says smallest exclusivly
FROM cbsa															-- this will pull the highest total pop by using desc and you limit it to only 1
	JOIN population USING (fipscounty)								-- to only show that highest one
	GROUP BY cbsaname
	ORDER BY total_pop ASC
	limit 1);

								--ANSWER:	MORRISTOWN TOTAL POP: 116352 SMALLEST, NASHVILLE TOTAL POP: 1830410 HIGHEST--


   -- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT  population,county
FROM population
	FULL JOIN fips_county USING (fipscounty)
	FULL JOIN cbsa USING  (fipscounty)
WHERE population IS NOT NULL
AND cbsa IS NULL
ORDER BY population DESC
LIMIT 1;
												--ANSWER:	Sevier largest population 95523--

--6. 

--    a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name,SUM(total_claim_count) AS total_claims 
FROM prescription
WHERE  total_claim_count >= 3000
GROUP BY drug_name;

--    b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name,SUM(total_claim_count) AS total_claims, opioid_drug_flag
FROM prescription
	FULL JOIN drug USING (drug_name)
WHERE  total_claim_count >= 3000
GROUP BY drug_name,OPIOID_DRUG_FLAG;

--    c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT 		drug_name,opioid_drug_flag,
			SUM(total_claim_count) AS total_claims,
			nppes_provider_last_org_name AS last_name,
			nppes_provider_first_name AS first_name
FROM		prescription
				FULL JOIN drug USING (drug_name)
				FULL JOIN prescriber USING (npi)
WHERE  total_claim_count >= 3000
GROUP BY drug_name,nppes_provider_last_org_name,nppes_provider_first_name,opioid_drug_flag;
									
																	--ANSWER:
								-----------------------------------------------------------------------------------
-- 								|			DRUG NAME			 	 OPIOID   CLAIMS	LAST NAME      FIRST NAME	|
								-----------------------------------------------------------------------------------
-- 								|		"FUROSEMIDE"					"N"		3083	"COX"			"MICHAEL"	|
-- 								|		"GABAPENTIN"					"N"		3531	"PENDLEY"		"BRUCE"		|
-- 								|		"HYDROCODONE-ACETAMINOPHEN"		"Y"		3376	"COFFEY"		"DAVID"		|
-- 								|		"LEVOTHYROXINE SODIUM"			"N"		3101	"HASEMEIER"		"ERIC"		|
-- 								|		"LEVOTHYROXINE SODIUM"			"N"		3023	"PENDLEY"		"BRUCE"		|
-- 								|		"LEVOTHYROXINE SODIUM"			"N"		3138	"SHATTUCK"		"DEAVER"	|
-- 								|		"LISINOPRIL"					"N"		3655	"PENDLEY"		"BRUCE"		|
--								|		"MIRTAZAPINE"					"N"		3085	"PENDLEY"		"BRUCE"		|
-- 								|		"OXYCODONE HCL"					"Y"		4538	"COFFEY"		"DAVID"		|
								-----------------------------------------------------------------------------------



--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.


--    a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi,drug_name
FROM prescriber
	CROSS JOIN drug
WHERE specialty_description ILIKE 'Pain Management'
AND nppes_provider_city ILIKE 'Nashville'
AND opioid_drug_flag ILIKE 'Y' ;

--    b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT prescriber.npi,
	drug.drug_name,
	SUM(total_claim_count) AS claim_count
FROM prescriber
	CROSS JOIN drug
	FULL JOIN prescription USING (drug_name)
WHERE specialty_description ILIKE 'Pain Management'
AND nppes_provider_city ILIKE 'Nashville'
AND opioid_drug_flag ILIKE 'Y' 
GROUP BY prescriber.npi, drug.drug_name;

--    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT 	prescriber.npi,
		drug.drug_name,
		COALESCE(SUM(total_claim_count),0) AS claim_count
FROM prescriber
	CROSS JOIN drug
	LEFT JOIN prescription USING (drug_name)
WHERE specialty_description ILIKE 'Pain Management'
AND nppes_provider_city ILIKE 'Nashville'
AND opioid_drug_flag ILIKE 'Y' 
GROUP BY prescriber.npi, drug.drug_name;


-------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------GROUPING SETS-----------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
														
														

--1. Write a query which returns the total number of claims for these two groups. Your output should look like this: 
								-----------------------------------------------------------------
								--					specialty_description 		 	|total_claims|
								-----------------------------------------------------------------
								--				Interventional Pain Management  	|   55906	 |
								--					Pain Management               	|   70853	 |
								-----------------------------------------------------------------
SELECT 		specialty_description, 
			SUM(total_claim_count) AS total_claims
	
FROM 		prescriber AS p1
			JOIN prescription AS p2 USING(npi)
	
WHERE 		specialty_description ILIKE 'interventional pain management'
			OR specialty_description ILIKE 'pain management'
	
GROUP BY	 specialty_description;


--2. Now, let's say that we want our output to also include the total number of claims between these two groups. Combine two queries with the UNION keyword to accomplish this. Your output should look like this:
												---------------------------------------------
--												|specialty_description         |total_claims|
--												|------------------------------|------------|
--												|                              |      126759|
--												|Interventional Pain Management|       55906|
--												|Pain Management               |       70853|
												---------------------------------------------
(SELECT 		specialty_description, 
			SUM(total_claim_count) AS total_claims	
FROM 		prescriber AS p1
			JOIN prescription AS p2 USING(npi)	
WHERE 		specialty_description ILIKE 'interventional pain management'
			OR specialty_description ILIKE 'pain management'	
GROUP BY	 specialty_description)

	UNION ALL

(SELECT 		specialty_description, 
			SUM(total_claim_count) AS total_claims	
FROM 		prescriber AS p1
			JOIN prescription AS p2 USING(npi)	
WHERE 		specialty_description ILIKE 'interventional pain management'
			OR specialty_description ILIKE 'pain management'
GROUP BY	 specialty_description);

--AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
                                  --this one should add both the sums from ipm and pm
(SELECT (SELECT SUM(total_claim_count) AS total_claims
	 	 FROM prescriber AS p1 JOIN prescription AS p2 USING(npi)		
		 WHERE specialty_description ILIKE 'interventional pain management')		
	+	
		(SELECT SUM(total_claim_count) AS total_claims
		 FROM prescriber AS p1 JOIN prescription AS p2 USING(npi)	
		 WHERE specialty_description ILIKE 'pain management') AS total	
 FROM prescriber AS p1
	  JOIN prescription AS p2 USING(npi))
	
UNION ALL
								-- this one should show the names interventional pain and pain management
(SELECT specialty_description
FROM 		prescriber AS p1
			JOIN prescription AS p2 USING(npi)
WHERE specialty_description ILIKE 'interventional pain management'
			OR specialty_description ILIKE 'pain management')










	

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------BONUS---------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
																

--	1. 
--		How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT COUNT(DISTINCT p1.npi) AS prescriber_npi,
	COUNT(DISTINCT p2.npi) AS prescription_npi,
	(COUNT(DISTINCT p1.npi)-COUNT(DISTINCT p2.npi)) AS diiference_between
FROM prescriber AS p1
	FULL JOIN prescription AS p2 USING (npi);
---------------------------------------------------------------------------
--	|	"prescriber_npi"	|  "prescription_npi"	|  "diiference_between"	|
--	|		25050			|		20592			|		  4458			|
----------------------------------------------------------------------------


--	2.
--	    a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT generic_name,SUM(total_claim_count) AS total_claim
FROM prescriber
	FULL JOIN PRESCRIPTION USING (npi)
	FULL JOIN drug USING (drug_name)
WHERE specialty_description ILIKE 'family_practice'
	AND total_claim_count IS NOT NULL
GROUP BY generic_name
ORDER BY total_claim DESC
LIMIT 5;
									--------------------------------------------
--									|	"generic_name"		|   "total_claim"	|
									--------------------------------------------
--									|"LEVOTHYROXINE SODIUM" |		406547		|
--									|"LISINOPRIL"           |		311506		|
--									|"ATORVASTATIN CALCIUM" |		308523		|
--									|"AMLODIPINE BESYLATE"  |		304343		|
--									|"OMEPRAZOLE"           |		273570		|
									--------------------------------------------

--	    b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT generic_name,SUM(total_claim_count) AS total_claim
FROM prescriber
	FULL JOIN PRESCRIPTION USING (npi)
	FULL JOIN drug USING (drug_name)
WHERE specialty_description ILIKE 'cardiology'
	AND total_claim_count IS NOT NULL
GROUP BY generic_name
ORDER BY total_claim DESC
LIMIT 5;
				----------------------------------------------
--				|	"generic_name"				"total_claim" |
				----------------------------------------------
--				|"ATORVASTATIN CALCIUM"		|		120662	  |
--				|"CARVEDILOL"				|		106812	  |
--				|"METOPROLOL TARTRATE"		|		93940	  |
--				|"CLOPIDOGREL BISULFATE"	|		87025	  |
--				|"AMLODIPINE BESYLATE"		|		86928	  |
				-----------------------------------------------



--	    c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single 			query to answer this question.
(SELECT generic_name,
		specialty_description,
		SUM(total_claim_count) AS total_claim
FROM prescriber
	FULL JOIN PRESCRIPTION USING (npi)
	FULL JOIN drug USING (drug_name)
WHERE specialty_description ILIKE 'family_practice'
	AND total_claim_count IS NOT NULL
GROUP BY generic_name,specialty_description
ORDER BY total_claim DESC
LIMIT 5)
UNION ALL
(SELECT generic_name,
		specialty_description,
		SUM(total_claim_count) AS total_claim
FROM prescriber
	FULL JOIN PRESCRIPTION USING (npi)
	FULL JOIN drug USING (drug_name)
WHERE specialty_description ILIKE 'cardiology'
	AND total_claim_count IS NOT NULL
GROUP BY generic_name,specialty_description
ORDER BY total_claim DESC
LIMIT 5)
ORDER BY total_claim DESC;
---------------------------------------------------------------------------------------
--		|	   "generic_name"		 	 |	"specialty_description"	 |	"total_claim"	|
---------------------------------------------------------------------------------------
--		|	"LEVOTHYROXINE SODIUM"	 	 |		"Family Practice"	 |		406547		|
--		|	"LISINOPRIL"			 	 |		"Family Practice"	 |		311506		|
--		|	"ATORVASTATIN CALCIUM"	 	 |		"Family Practice"	 |		308523		|
--		|	"AMLODIPINE BESYLATE"	  	 |		"Family Practice"	 |		304343		|
--		|	"OMEPRAZOLE"			  	 |		"Family Practice"	 |		273570		|
--		|	"ATORVASTATIN CALCIUM"	 	 |		  "Cardiology"		 |		120662		|
--		|	"CARVEDILOL"			 	 |		  "Cardiology"		 |		106812		|
--		|	"METOPROLOL TARTRATE"	 	 |		  "Cardiology"		 |		93940		|
--		|	"CLOPIDOGREL BISULFATE"	 	 |		  "Cardiology"		 |		87025		|
--		|	"AMLODIPINE BESYLATE"	 	 |		  "Cardiology"		 |		86928		|
---------------------------------------------------------------------------------------

--3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.

--    a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

SELECT npi,SUM(total_claim_count) AS total_number_claims,nppes_provider_city
FROM prescriber
	FULL JOIN prescription USING (npi)
WHERE nppes_provider_city ILIKE 'NASHVILLE'
GROUP BY npi,nppes_provider_city
ORDER BY total_number_claims DESC
LIMIT 5;
   
--    b. Now, report the same for Memphis.
SELECT npi,SUM(total_claim_count) AS total_number_claims, nppes_provider_city
FROM prescriber
	FULL JOIN prescription USING (npi)
WHERE total_claim_count IS NOT NULL
	AND nppes_provider_city ILIKE 'MEMPHIS'
GROUP BY npi,nppes_provider_city
ORDER BY total_number_claims DESC
LIMIT 5;


--    c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
(SELECT npi,SUM(total_claim_count) AS total_number_claims,nppes_provider_city
FROM prescriber
	FULL JOIN prescription USING (npi)
WHERE total_claim_count IS NOT NULL
	AND nppes_provider_city ILIKE 'Nashville'
GROUP BY npi,nppes_provider_city
ORDER BY total_number_claims DESC
limit 5)
UNION
(SELECT npi,SUM(total_claim_count) AS total_number_claims, nppes_provider_city
FROM prescriber
	FULL JOIN prescription USING (npi)
WHERE total_claim_count IS NOT NULL
	AND nppes_provider_city ILIKE 'MEMPHIS'
GROUP BY npi,nppes_provider_city
ORDER BY total_number_claims DESC
limit 5 )
UNION
	(SELECT npi,SUM(total_claim_count) AS total_number_claims,nppes_provider_city
FROM prescriber
	FULL JOIN prescription USING (npi)
WHERE total_claim_count IS NOT NULL
	AND nppes_provider_city ILIKE 'KNOXVILLE'
GROUP BY npi,nppes_provider_city
ORDER BY total_number_claims DESC
limit 5)
UNION
(SELECT npi,SUM(total_claim_count) AS total_number_claims, nppes_provider_city
FROM prescriber
	FULL JOIN prescription USING (npi)
WHERE total_claim_count IS NOT NULL
	AND nppes_provider_city ILIKE 'CHATTANOOGA'
GROUP BY npi,nppes_provider_city
ORDER BY total_number_claims DESC
limit 5 )
ORDER BY nppes_provider_city;

--4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths

SELECT SUM(overdose_deaths) AS total_deaths,
		county
FROM fips_county AS fc
	FULL JOIN overdose_deaths AS od 
	ON (fc.fipscounty::INT) = od.fipscounty
WHERE overdose_deaths >
			(SELECT AVG(overdose_deaths)
			 FROM overdose_deaths)
GROUP BY county
ORDER BY total_deaths DESC



--5.

--    a. Write a query that finds the total population of Tennessee.





    
--    b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

















