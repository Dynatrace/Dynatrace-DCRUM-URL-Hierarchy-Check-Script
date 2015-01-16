SET NOCOUNT ON;

SELECT 'URL Hierarchy for All Other (should return one row)';
SELECT l0.row_id, l0.url, l0.raw_url_id, l0.flags, l1.row_id, l1.url, l1.flags, l1.uid, l2.row_id, l2.url, l2.flags, l3.row_id, l3.url, l3.flags FROM RtmUrl l0 LEFT JOIN RtmUrlMapping0to1 m0 ON m0.child_id = l0.row_id LEFT JOIN RtmUrlLabelLevel1 l1 ON m0.parent_id = l1.row_id LEFT JOIN RtmUrlMapping1to2 m1 ON m1.child_id = l1.row_id LEFT JOIN RtmUrlLabelLevel2 l2 ON m1.parent_id = l2.row_id LEFT JOIN RtmUrlMapping2to3 m2 ON m2.child_id = l2.row_id LEFT JOIN RtmUrlLabelLevel3 l3 ON m2.parent_id = l3.row_id WHERE l0.url = ' ';

-- missing urls from RtmServer
SELECT 'RtmServer entries with no reference to RtmUrl (should be empty)'
SELECT * FROM RtmServer WHERE url_id NOT IN (SELECT row_id FROM RtmUrl) and row_id NOT IN (SELECT svr_id FROM RtmBussGroup);

-- missing raw_urls
SELECT 'RtmUrl entries with no reference to RtmRawUrl (should be empty)'
SELECT * FROM RtmUrl WHERE raw_url_id <> -1 and raw_url_id NOT IN (SELECT row_id FROM RtmRawUrl) AND flags & 4 = 0 AND row_id NOT IN (SELECT url_id FROM RtmBussGroup WHERE flags & 62 = 0);

-- urls without server reference
SELECT 'RtmUrl entries with no reference to RtmServer (might not be empty - diagnostic)'
SELECT * FROM RtmUrl WHERE flags & 4 = 0 AND row_id NOT IN (SELECT url_id FROM RtmBussGroup WHERE flags & 62 = 0) and row_id not IN (SELECT url_id FROM RtmServer);

-- level 0
SELECT 'RtmUrlMapping0to1 entries with no reference to RtmUrl (should be empty)'
SELECT * FROM RtmUrlMapping0to1 WHERE child_id NOT IN ( SELECT row_id FROM Rtmurl);

SELECT 'RtmUrlMapping0to1 entries with no reference to RtmUrlLabelLevel1 (should be empty)'
SELECT * FROM RtmUrlMapping0to1 WHERE parent_id NOT IN ( SELECT row_id FROM RtmUrlLabelLevel1);

SELECT 'RtmUrl entries with no reference in RtmUrlMapping0to1 (should be empty)'
SELECT * FROM Rtmurl WHERE flags & 4 = 0 AND row_id NOT IN (SELECT url_id FROM RtmBussGroup WHERE flags & 62 = 0) and row_id NOT IN (SELECT child_id FROM RtmUrlMapping0to1);

-- level 1
SELECT 'RtmUrlMapping1to2 entries with no reference to RtmUrlLabelLevel1 (should be empty)'
SELECT * FROM RtmUrlMapping1to2 WHERE child_id NOT IN (SELECT row_id FROM RtmUrlLabelLevel1);

SELECT 'RtmUrlMapping1to2 entries with no reference to RtmUrlLabelLevel2 (should be empty)'
SELECT * FROM RtmUrlMapping1to2 WHERE parent_id NOT IN ( SELECT row_id FROM RtmUrlLabelLevel2);

SELECT 'RtmUrlLabelLevel1 entries with no reference in RtmUrlMapping1to2 (should be empty)'
SELECT * FROM RtmUrlLabelLevel1 WHERE flags & 4 = 0 AND row_id NOT IN (SELECT url_id FROM RtmBussGroup WHERE flags & 4 <> 0) and row_id NOT IN (SELECT child_id FROM RtmUrlMapping1to2);

-- level 2
SELECT 'RtmUrlMapping2to3 entries with no reference in RtmUrlLabelLevel2 (should be empty)';
SELECT * FROM RtmUrlMapping2to3 WHERE child_id NOT IN ( SELECT row_id FROM RtmUrlLabelLevel2);

SELECT 'RtmUrlMapping2to3 entries with no reference in RtmUrlLabelLevel3 (should be empty)';
SELECT * FROM RtmUrlMapping2to3 WHERE parent_id NOT IN ( SELECT row_id FROM RtmUrlLabelLevel3);

SELECT 'RtmUrlLabelLevel2 entries with no reference in RtmUrlMapping2to3 (should be empty)';
SELECT * FROM RtmUrlLabelLevel2 WHERE flags & 4 = 0 AND row_id NOT IN (SELECT url_id FROM RtmBussGroup WHERE flags & 8 <> 0) and row_id NOT IN (SELECT child_id FROM RtmUrlMapping2to3);

-- level 3
SELECT 'RtmUrlLabelLevel3 entries with no reference in RtmUrlMapping2to3 (should be empty)';
SELECT * FROM RtmUrlLabelLevel3 WHERE flags & 4 = 0 AND row_id NOT IN (SELECT url_id FROM RtmBussGroup WHERE flags & 16 <> 0) and row_id NOT IN (SELECT parent_id FROM RtmUrlMapping2to3);

-- duplicated urls
SELECT 'Duplicated RtmUrl entries (should be empty)';
with numbered AS ( SELECT row_id, url ,  ROW_NUMBER () OVER (
       PARTITION BY url ORDER BY url) AS nr
       FROM RtmUrl)
SELECT * FROM numbered WHERE nr > 1 and row_id NOT IN ( SELECT url_id
   FROM
        Rtmbussgroupdef bgconf, Rtmbussgroup bg
   WHERE
        row_id = bg_id
        AND
        bg .url_id <> -1
        AND
        bgconf .flags & 0x1f < 2
   GROUP BY url_id);

-- duplicated servers
SELECT 'Duplicated RtmServer entries (should be empty)';
SELECT addr_svr
     , url_id
     , COUNT(*) AS CNT
FROM
     RtmServer
GROUP BY
     addr_svr
  , url_id
HAVING
     COUNT(*) > 1;

-- hierarchy check
SELECT 'Total URL Hierarchy inconsistency check (should be empty)';
SELECT *
FROM
     RtmUrl
WHERE
     row_id NOT IN (SELECT l0.row_id
                       FROM
                            RtmUrl l0
                            LEFT JOIN RtmUrlMapping0to1 m0
                                 ON m0.child_id = l0.row_id
                            LEFT JOIN RtmUrlLabelLevel1 l1
                                 ON m0.parent_id = l1.row_id
                            LEFT JOIN RtmUrlMapping1to2 m1
                                 ON m1.child_id = l1.row_id
                            LEFT JOIN RtmUrlLabelLevel2 l2
                                 ON m1.parent_id = l2.row_id
                            LEFT JOIN RtmUrlMapping2to3 m2
                                 ON m2.child_id = l2.row_id
                            LEFT JOIN RtmUrlLabelLevel3 l3
                                 ON m2.parent_id = l3.row_id);