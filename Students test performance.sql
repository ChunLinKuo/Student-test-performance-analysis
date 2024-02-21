SELECT *
FROM [ PorfolioProject].[dbo].[StudentsPerformance_V2]

-- Checking null value
SELECT *
FROM[ PorfolioProject].[dbo].[StudentsPerformance_V2]
WHERE math_score IS NULL
OR writing_score IS NULL
OR reading_score IS NULL

--Chekcing duplictes
WITH Duplicate_CTE AS (
SELECT*, ROW_NUMBER () OVER (Partition by lunch,
                                          test_preparation_course,
					  parental_level_of_education,
	                                  gender,
					  race_ethnicity,
					  math_score,
					  reading_score,
					  writing_score 
ORDER BY race_ethnicity DESC) AS Row_num
FROM [ PorfolioProject].[dbo].[StudentsPerformance_V2]
)

SELECT *
FROM Duplicate_CTE
WHERE row_num <> 1

--Math average score by ethnicity
SELECT race_ethnicity, AVG(math_score)
FROM [ PorfolioProject].[dbo].[StudentsPerformance_V2]
GROUP BY race_ethnicity

--Check overall average math score and differene  
SELECT *,
       AVG(math_score) OVER () AS overall_avg_math_score,
       math_score - AVG(math_score) OVER () AS DIFF
FROM [ PorfolioProject].[dbo].[StudentsPerformance_V2]

--Average test score by gender
SELECT *,
       AVG(math_score) OVER (Partition by gender) AS avg_math_score,
	   AVG(reading_score) OVER (Partition by gender) AS avg_reading_score,
	   AVG(writing_score) OVER (Partition by gender) AS avg_writing_score
FROM [ PorfolioProject].[dbo].[StudentsPerformance_V2]

--Giving Feedback by comparing the math score by gender
WITH AVG_MATH_CTE AS (
SELECT *,
       AVG(math_score) OVER (Partition by gender) AS avg_math_score,
	   AVG(reading_score) OVER (Partition by gender) AS avg_reading_score,
	   AVG(writing_score) OVER (Partition by gender) AS avg_writing_score
FROM [ PorfolioProject].[dbo].[StudentsPerformance_V2]
)
SELECT *,
CASE WHEN math_score > avg_math_score THEN 'Excedding'
     WHEN math_score < avg_math_score THEN 'Working Toward'
END AS Avg_math_score_feedback,
	CASE WHEN reading_score > avg_reading_score THEN 'Exceeding'
         WHEN reading_score < avg_reading_score THEN 'Working Toward'
    END AS Avg_reading_score_feedback,
	CASE WHEN writing_score > avg_writing_score THEN 'Exceeding'
         WHEN writing_score < avg_writing_score THEN 'Working Toward'
    END AS Avg_writing_score_feedback
FROM AVG_MATH_CTE

SELECT *
FROM Duplicate_CTE
WHERE row_num <> 1

-- Drop the temporary table if it exists
IF OBJECT_ID('tempdb..#feedbackset') IS NOT NULL
    DROP TABLE #feedbackset;

-- Create the temporary table
CREATE TABLE #feedbackset
(
    Gender VARCHAR(100),
    race_ethnicity VARCHAR(100),
    parental_level_of_education VARCHAR(100),
    lunch VARCHAR(100),
    test_preparation_course VARCHAR(100),
    math_score INT,
    reading_score INT,
    writing_score INT,
    avg_math_score DECIMAL,
    avg_reading_score DECIMAL,
    avg_writing_score DECIMAL,
    avg_math_score_feedback VARCHAR(100),
    avg_reading_score_feedback VARCHAR(100),
    avg_writing_score_feedback VARCHAR(100)
);

-- CTE definition
WITH AVG_MATH_CTE AS (
    SELECT *,
           AVG(math_score) OVER (Partition by gender) AS avg_math_score,
	       AVG(reading_score) OVER (Partition by gender) AS avg_reading_score,
	       AVG(writing_score) OVER (Partition by gender) AS avg_writing_score
    FROM [ PorfolioProject].[dbo].[StudentsPerformance_V2]
)
-- Insert data into the temporary table from AVG_MATH_CTE
INSERT INTO #feedbackset (
    Gender, 
    race_ethnicity, 
    parental_level_of_education, 
    lunch, 
    test_preparation_course, 
    math_score, 
    reading_score, 
    writing_score, 
    avg_math_score, 
    avg_reading_score, 
    avg_writing_score, 
    avg_math_score_feedback,
    avg_reading_score_feedback,
    avg_writing_score_feedback
)
SELECT *,
    CASE WHEN math_score > avg_math_score THEN 'Exceeding'
         WHEN math_score < avg_math_score THEN 'Working Toward'
    END AS Avg_math_score_feedback,
	CASE WHEN reading_score > avg_reading_score THEN 'Exceeding'
         WHEN reading_score < avg_reading_score THEN 'Working Toward'
    END AS Avg_reading_score_feedback,
	CASE WHEN writing_score > avg_writing_score THEN 'Exceeding'
         WHEN writing_score < avg_writing_score THEN 'Working Toward'
    END AS Avg_writing_score_feedback
FROM AVG_MATH_CTE;

-- Count how many exceeding and working toward by ethnicity and gender
SELECT race_ethnicity,Gender,
       COUNT(CASE WHEN avg_math_score_feedback = 'Exceeding' THEN 1 END) AS Math_Exceeding_Count,
       COUNT(CASE WHEN avg_math_score_feedback = 'Working Toward' THEN 1 END) AS Math_Working_Toward_Count,
	   COUNT(CASE WHEN avg_reading_score_feedback = 'Exceeding' THEN 1 END) AS Reading_Exceeding_Count,
       COUNT(CASE WHEN avg_reading_score_feedback = 'Working Toward' THEN 1 END) AS Reading_Working_Toward_Count,
	   COUNT(CASE WHEN avg_writing_score_feedback = 'Exceeding' THEN 1 END) AS Writing_Exceeding_Count,
       COUNT(CASE WHEN avg_writing_score_feedback = 'Working Toward' THEN 1 END) AS Writing_Working_Toward_Count
FROM #feedbackset
GROUP BY race_ethnicity,Gender;
