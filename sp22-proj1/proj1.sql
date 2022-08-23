-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT nameFirst, nameLast, birthYear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT nameFirst, nameLast, birthYear
  FROM people
  WHERE nameFirst = ' ' OR
        nameFirst LIKE '% ' OR
        nameFirst LIKE ' %' OR
        nameFirst LIKE '% %'
  ORDER BY nameFirst ASC, nameLast ASC
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthYear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthYear
  ORDER BY birthYear ASC
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthYear, avgheight, count
  FROM q1iii
  WHERE avgheight > 70
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT nameFirst, nameLast, people.playerId, yearid
  FROM people, halloffame
  WHERE people.playerId = halloffame.playerId AND
        halloffame.inducted = 'Y'
  ORDER BY yearid DESC, people.playerId ASC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT nameFirst, nameLast, people.playerId, collegeplaying.schoolId, yearid
  FROM people, halloffame, collegeplaying, schools
  WHERE people.playerId = halloffame.playerId AND
        people.playerId = collegeplaying.playerid AND
        collegeplaying.schoolId = schools.schoolId AND
        schools.schoolState = 'CA' AND
        halloffame.inducted = 'Y'
  ORDER BY yearid DESC, collegeplaying.schoolId ASC, people.playerId ASC
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT T.playerId, T.nameFirst, T.nameLast, T.schoolId
  FROM ((SELECT playerId, nameFirst, nameLast FROM people) NATURAL JOIN
       (SELECT playerId FROM halloffame WHERE inducted = 'Y') NATURAL LEFT OUTER JOIN
       (SELECT playerid as playerId, schoolId FROM collegeplaying) NATURAL LEFT OUTER JOIN
       (SELECT schoolId FROM schools)) AS T
  ORDER BY T.playerId DESC, T.schoolId ASC
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  WITH bat_with_slg AS (
    SELECT playerID AS playerId, yearID,
          (H + H2B + 2* H3B + 3 * HR) / CAST(AB AS FLOAT) AS slg
    FROM batting
    WHERE AB > 50
  )
  SELECT T.playerId, T.nameFirst, T.nameLast, T.yearID, T.slg
  FROM ((SELECT playerId, nameFirst, nameLast FROM people) NATURAL JOIN bat_with_slg) AS T
  ORDER BY T.slg DESC, T.yearID ASC, T.playerId ASC
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  WITH bat_group_with_id AS (
    SELECT playerID AS playerId,
           (SUM(H) + SUM(H2B) + 2* SUM(H3B) + 3 * SUM(HR)) / CAST(SUM(AB) AS FLOAT) AS lslg
    FROM batting
    GROUP BY playerID
    HAVING SUM(AB) > 50
  )
  SELECT T.playerId, T.nameFirst, T.nameLast, T.lslg
  FROM ((SELECT playerId, nameFirst, nameLast FROM people) NATURAL JOIN bat_group_with_id) AS T
  ORDER BY T.lslg DESC, T.playerId ASC
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  WITH bat_group_with_id AS (
    SELECT playerID AS playerId,
           (SUM(H) + SUM(H2B) + 2* SUM(H3B) + 3 * SUM(HR)) / CAST(SUM(AB) AS FLOAT) AS lslg
    FROM batting
    GROUP BY playerID
    HAVING SUM(AB) > 50
  )
  SELECT T.nameFirst, T.nameLast, T.lslg
  FROM ((SELECT playerId, nameFirst, nameLast FROM people) NATURAL JOIN bat_group_with_id) AS T
  WHERE T.lslg > (SELECT lslg FROM bat_group_with_id WHERE playerID = 'mayswi01')
  ORDER BY T.lslg DESC, T.playerId ASC
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearID, MIN(salary), MAX(salary), AVG(salary)
  FROM salaries
  GROUP BY yearID
  ORDER BY yearID ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  WITH bins_statistics(binid, binstart, width) AS (
    SELECT MIN(salary), MAX(salary), CAST (((MAX(salary) - MIN(salary))/10) AS INT)
    FROM salaries
  ), bins(binid, binstart, width) AS (
    SELECT CAST ((salary/width) AS INT), binstart, width
    FROM salaries, bins_statistics
    WHERE yearid = 2016
  )

  SELECT binid, 507500.0 + binid * 3249250,3756750.0 + binid * 3249250, count(*)
  FROM binids, salaries
  WHERE (salary BETWEEN 507500.0 + binid*3249250 AND 3756750.0 + binid * 3249250 ) AND yearID='2016'
  GROUP BY binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  SELECT q4i2.yearid, q4i2.min - q4i1.min,
         q4i2.max - q4i1.max, q4i2.avg - q4i1.avg
  FROM q4i AS q4i1, q4i AS q4i2
  WHERE q4i1.yearid + 1 = q4i2.yearid
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  WITH max_2020_and_2021 AS (
    SELECT yearID, playerID, MAX(salary) AS maxSalary
    FROM salaries
    GROUP BY yearID
    HAVING yearID = 2000 OR yearID = 2001
  )
  SELECT people.playerId, nameFirst, nameLast, maxSalary, yearID
  FROM people, max_2020_and_2021
  WHERE people.playerId = max_2020_and_2021.playerID
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg)
AS
  SELECT allstarfull.teamID, MAX(salary) - MIN(salary)
  FROM salaries, allstarfull
  WHERE salaries.yearID = 2016 AND salaries.playerID = allstarfull.playerID
        AND allstarfull.yearID = 2016
  GROUP BY allstarfull.teamID
;

