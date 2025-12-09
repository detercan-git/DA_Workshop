/* Create Table for Agent Lookup and insert records */
CREATE OR REPLACE TABLE LU_CCT_AGENT (
 ID_CCT_AGENT integer,
 DS_CCT_AGENT STRING);
INSERT INTO LU_CCT_AGENT 
VALUES 
    (1, 'John Smith'),
    (2, 'Sarah Johnson'),
    (3, 'Michael Brown'),
    (4, 'Emily Davis'),
    (5, 'David Wilson'),
    (6, 'Jessica Taylor'),
    (7, 'Robert Martinez'),
    (8, 'Lisa Anderson'),
    (9, 'James Thompson'),
    (10, 'Michelle Garcia');

/* Create Table for Supervisor Lookup and insert records */
CREATE OR REPLACE TABLE LU_CCT_SUPERVISOR (
 ID_CCT_SUPERVISOR integer,
 DS_CCT_SUPERVISOR STRING);
INSERT INTO LU_CCT_SUPERVISOR
VALUES 
    (1, 'John Smith'),
    (2, 'Sarah Johnson'),
    (3, 'Michael Brown'),
    (4, 'Emily Davis'),
    (5, 'David Wilson'),
    (6, 'Jessica Taylor'),
    (7, 'Robert Martinez'),
    (8, 'Lisa Anderson'),
    (9, 'James Thompson'),
    (10, 'Michelle Garcia');

/* Create Table for grouping of audit check list and create records */
CREATE OR REPLACE TABLE LU_CCT_CALL_AUDIT_GROUP (
 ID_CCT_CALL_AUDIT_GROUP integer,
 DS_CCT_CALL_AUDIT_GROUP STRING);
INSERT INTO LU_CCT_CALL_AUDIT_GROUP VALUES (1,'Adherence to Protocols');
INSERT INTO LU_CCT_CALL_AUDIT_GROUP VALUES (2,'Communication Skills');
INSERT INTO LU_CCT_CALL_AUDIT_GROUP VALUES (3,'Context');

/* Create Table for audit check list and create records */
CREATE OR REPLACE TABLE LU_CCT_CALL_AUDIT_ITEM (
 ID_CCT_CALL_AUDIT_GROUP integer,
 ID_CCT_CALL_AUDIT_ITEM integer,
 DS_CCT_CALL_AUDIT_ITEM STRING,
 DS_CCT_CALL_AUDIT_ITEM_PROMPT STRING);
 insert into LU_CCT_CALL_AUDIT_ITEM VALUES (1,10,'Introducing the company','Did the agent introduce the company name in this call? Return a JSON with keys "complied" (boolean),  and "explanation" ');
 insert into LU_CCT_CALL_AUDIT_ITEM VALUES (1,11,'Greet the customer','Did the agent greet the customer? Return a JSON with keys "complied" (boolean) and "explanation" ');
 insert into LU_CCT_CALL_AUDIT_ITEM VALUES (1,12,'Offered additional help','Did the agent ask if they can help for any other topic to the customer? Return a JSON with keys "complied" (boolean) and "explanation" ');

/* Create script for the main log table for the calls*/ 
create OR REPLACE table TR_CCT_CALL_LOG (
    FL_CCT_INBOUND boolean,
    ID_CALL BIGINT,
    ID_CCT_AGENT integer,
    ID_CCT_SUPERVISOR integer,
    DT_CALL_DATE TIMESTAMP,
    DS_CALL_CONTENT VARIANT,
    DS_CALL_FILE STRING,
    DS_CALL_TEXT VARIANT,
    DS_CALL_SENTIMENT VARIANT,
    MT_CALL_DURATION DOUBLE
    );

/* Table for the audiot results */ 
create OR REPLACE  table TR_CCT_CALL_AUDIT (
 ID_CALL BIGINT,
 ID_CCT_CALL_AUDIT_ITEM STRING,
 DS_CCT_CALL_AUDIT_MODEL STRING,
 DS_CCT_CALL_AUDIT_JSON VARIANT,
 MT_CCT_CALL_AUDIT_SCORE INTEGER
);

DELETE FROM TR_CCT_CALL_LOG;

INSERT INTO TR_CCT_CALL_LOG
SELECT true,2,UNIFORM(1, 10, RANDOM())::INTEGER,UNIFORM(1, 10, RANDOM())::INTEGER,current_date(), AI_TRANSCRIBE(TO_FILE('@"CALLCENTER_ASSIST"."VOICE_FILES"."STAGE_FOR_VOICE"/resources_sample-calls.mp3'), {'timestamp_granularity': 'speaker'}), 'resources_sample-calls.mp3',null ,null,null;

INSERT INTO TR_CCT_CALL_LOG
SELECT true,5,UNIFORM(1, 10, RANDOM())::INTEGER,UNIFORM(1, 10, RANDOM())::INTEGER,current_date(), AI_TRANSCRIBE(TO_FILE('@"CALLCENTER_ASSIST"."VOICE_FILES"."STAGE_FOR_VOICE"/English_1.mp3'), {'timestamp_granularity': 'speaker'}), 'English_1.mp3' ,null,null,null;

INSERT INTO TR_CCT_CALL_LOG
SELECT true,6,UNIFORM(1, 10, RANDOM())::INTEGER,UNIFORM(1, 10, RANDOM())::INTEGER,current_date(), AI_TRANSCRIBE(TO_FILE('@"CALLCENTER_ASSIST"."VOICE_FILES"."STAGE_FOR_VOICE"/English_2.mp3'), {'timestamp_granularity': 'speaker'}), 'English_2.mp3' ,null,null,null;

INSERT INTO TR_CCT_CALL_LOG
SELECT true,7,UNIFORM(1, 10, RANDOM())::INTEGER,UNIFORM(1, 10, RANDOM())::INTEGER,current_date(), AI_TRANSCRIBE(TO_FILE('@"CALLCENTER_ASSIST"."VOICE_FILES"."STAGE_FOR_VOICE"/Arabic_1.mp3'), {'timestamp_granularity': 'speaker'}), 'Arabic_1.mp3' ,null,null,null;

INSERT INTO TR_CCT_CALL_LOG
SELECT true,8,UNIFORM(1, 10, RANDOM())::INTEGER,UNIFORM(1, 10, RANDOM())::INTEGER,current_date(), AI_TRANSCRIBE(TO_FILE('@"CALLCENTER_ASSIST"."VOICE_FILES"."STAGE_FOR_VOICE"/Arabic_2.mp3'), {'timestamp_granularity': 'speaker'}), 'Arabic_2.mp3' ,null,null,null;

INSERT INTO TR_CCT_CALL_LOG
SELECT true,9,UNIFORM(1, 10, RANDOM())::INTEGER,UNIFORM(1, 10, RANDOM())::INTEGER,current_date(), AI_TRANSCRIBE(TO_FILE('@"CALLCENTER_ASSIST"."VOICE_FILES"."STAGE_FOR_VOICE"/Arabic_3.mp3'), {'timestamp_granularity': 'speaker'}), 'Arabic_3.mp3' ,null,null,null;

-- See Transcribed Files
SELECT ID_CALL, DS_CALL_CONTENT, DS_CALL_FILE, DS_CALL_TEXT, DS_CALL_SENTIMENT, MT_CALL_DURATION FROM TR_CCT_CALL_LOG 

-- Seperate the text, check the sentiment and record the duration
UPDATE  TR_CCT_CALL_LOG  SET
  DS_CALL_TEXT = DS_CALL_CONTENT:text,
  DS_CALL_SENTIMENT = AI_SENTIMENT(DS_CALL_CONTENT:text),
  MT_CALL_DURATION = DS_CALL_CONTENT:audio_duration::double;

SELECT ID_CALL, DS_CALL_CONTENT, DS_CALL_FILE, DS_CALL_TEXT, DS_CALL_SENTIMENT, MT_CALL_DURATION FROM TR_CCT_CALL_LOG ;

-- Convert JSON to structured data
UPDATE  TR_CCT_CALL_LOG  SET DS_CALL_SENTIMENT=DS_CALL_SENTIMENT:categories[0].sentiment;

SELECT ID_CALL, DS_CALL_CONTENT, DS_CALL_FILE, DS_CALL_TEXT, DS_CALL_SENTIMENT, MT_CALL_DURATION FROM TR_CCT_CALL_LOG ;


/* START AUIDITING PROCESS */ 
SELECT * FROM LU_CCT_CALL_AUDIT_ITEM;

DELETE FROM TR_CCT_CALL_AUDIT

-- Do the initial Audit
INSERT INTO TR_CCT_CALL_AUDIT
SELECT 
  ID_CALL,
  ID_CCT_CALL_AUDIT_ITEM,
  'snowflake-arctic',
  AI_COMPLETE('snowflake-arctic', CONCAT(DS_CCT_CALL_AUDIT_ITEM_PROMPT,  DS_CALL_TEXT)) ,
  NULL
FROM TR_CCT_CALL_LOG, LU_CCT_CALL_AUDIT_ITEM;

SELECT * FROM TR_CCT_CALL_AUDIT


-- UPATE AUDIT SCORE FOR A STRUCTURED DATA
UPDATE TR_CCT_CALL_AUDIT SET MT_CCT_CALL_AUDIT_SCORE= CASE WHEN PARSE_JSON(DS_CCT_CALL_AUDIT_JSON):complied = true THEN 1 ELSE 0 END;

SELECT * FROM TR_CCT_CALL_AUDIT

/* EXAMPLE FOR THE SEGMENTS OF THE TALK */
SELECT
    DS_CALL_FILE,
value:speaker_label::string as SPEAKER,
value:start::double as pSTART,
value:end::double as pEND,
value:end::double-value:start::double duration,
value:text::text text,
AI_SENTIMENT(value:text::text) Sentiment,
VALUE
FROM TR_CCT_CALL_LOG
 ,  LATERAL FLATTEN( INPUT => DS_CALL_CONTENT:segments )
 WHERE DS_CALL_FILE='English_1.mp3'
 




