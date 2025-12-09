-- Use Case 1 : Document AI

-- 1. Parse the PDF into a temp table
CREATE OR REPLACE TEMPORARY TABLE parsed_pdf_content AS
SELECT 
    SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
        '@CALLCENTER_ASSIST.VOICE_FILES.CONTRACTS', 
        'Contract1.pdf'
    ):content AS full_text;

select * from parsed_pdf_content

-- 2. Query the table and run AI Complete on the text
SELECT 
    AI_COMPLETE(
        'llama3.1-70b',
        CONCAT(
            'Context: ',
            LEFT(full_text, 100000),
            '\n\nQuestion: What are the LIMITATION OF LIABILITY? Answer verbatim from context.'
        )
    ) AS extraction_result
FROM parsed_pdf_content;

SELECT 
AI_COMPLETE(
        'llama3.1-70b',
        CONCAT('Context: ',full_text,'\n\nQuestion: Summarize the LIMITATION OF LIABILITY? ')
        ) AS extraction_result
FROM parsed_pdf_content;

/* Using AI_COMPLETE AND AI_EXTRACT for the same task */ 
SELECT
    AI_COMPLETE(
        'llama3.1-70b',
        CONCAT('Context: ',full_text,'\n\nQuestion: What is the telephone number of Aviation Technical Services, Inc.? ')
        ) AS extraction_result
FROM parsed_pdf_content;

SELECT 
   AI_EXTRACT(
        file => TO_FILE('@CALLCENTER_ASSIST.VOICE_FILES.CONTRACTS/Contract1.pdf'),        
        responseFormat => {
            'ats_phone_number': 'What is the telephone number of Aviation Technical Services, Inc.?'
        }
    ) AS extraction_result;

/* EXAMPLE FOR PROCESSING MULTIPLE FILES AT A SINGLE PATH */

-- Enable the directory listing for your stage
ALTER STAGE CONTRACTS SET DIRECTORY = (ENABLE = TRUE);

-- Refresh it to make sure it sees all current files
ALTER STAGE CONTRACTS REFRESH;

SELECT 
    RELATIVE_PATH as file_name, -- Shows you which document the answer belongs to
    AI_EXTRACT(
        file => TO_FILE('@CALLCENTER_ASSIST.VOICE_FILES.CONTRACTS/' || RELATIVE_PATH), -- Dynamically picks each file
        responseFormat => {
            -- Row 1: Intel Build
            'item_1_intel_desc': 'What is the Detailed Configuration for the Item 1 Assembled Graphics Desktop Intel Build?',
            'item_1_intel_price': 'What is the Amount for the Item 1 Intel Build?',
            
            -- Row 2: AMD Build
            'item_2_amd_desc': 'What is the Detailed Configuration for the Item 2 Assembled Graphics Desktop AMD Build?',
            'item_2_amd_price': 'What is the Amount for the Item 2 AMD Build?',
            
            -- Row 3: OS
            'item_3_os_desc': 'What is the Operating System description in Item 3?',
            'item_3_os_price': 'What is the Amount for Item 3?',

            -- Terms
            'tax_info': 'What is the GST percentage mentioned?',
            'payment_terms': 'What are the payment terms?'
        }
    ) AS extraction_result
FROM DIRECTORY(@CALLCENTER_ASSIST.VOICE_FILES.CONTRACTS)
WHERE RELATIVE_PATH LIKE 'Quotation_Details_V%';


ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- Use Case 2: Contract Comparison
WITH parsed_docs AS (
    SELECT 
        relative_path AS filename,
        -- Use PARSE_DOCUMENT with the OCR mode option
        SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
            '@CALLCENTER_ASSIST.VOICE_FILES.CONTRACTS', 
            relative_path,
            {'mode': 'OCR'}
        ):content AS doc_text
    FROM DIRECTORY(@CALLCENTER_ASSIST.VOICE_FILES.CONTRACTS)
    WHERE relative_path IN ('Quotation_Details_V1.pdf', 'Quotation_Details_V2.pdf') 
),

-- 2. Combine content
combined_context AS (
    SELECT 
        LISTAGG(
            CONCAT(
                '==================================================\n',
                'DOCUMENT NAME: ', filename, '\n',
                '==================================================\n',
                COALESCE(doc_text, ''),
                '\n\n'
            ), 
            ''
        ) AS full_context_blob
    FROM parsed_docs
)

-- 3. Run the "Executive Summary" Prompt
SELECT 
    SNOWFLAKE.CORTEX.COMPLETE(
        'openai-gpt-4.1', -- Using a standard high-performance model
        CONCAT(
            'You are a Decision Support Engine. Your goal is to output a clean, decision-ready comparison.\n\n',

            '### INSTRUCTIONS ###\n',
            '1. ANALYZE (Internal): Identify the document type and the top 5-7 critical comparison criteria. Do not output this list separately.\n',
            '2. OUTPUT FORMAT: Output ONLY two sections: A Comparison Table and a Final Verdict.\n\n',

            '### THE COMPARISON TABLE ###\n',
            'Create a Markdown table with exactly these 4 columns:\n',
            '| Criteria | [Document 1 Name] | [Document 2 Name] | Winner/Verdict |\n',
            '-- Rules for the "Winner/Verdict" column: Explicitly state which document is better and why.\n',
            '-- Rules for Data: Extract exact values. If data is missing, write "MISSING".\n\n',

            '### FINAL VERDICT ###\n',
            'Write a concise paragraph recommending the best option based on the "Winner" column count and critical trade-offs.\n\n',

            '### DOCUMENT CONTENT ###\n',
            full_context_blob,
            
            '\n\n### EXECUTIVE RESPONSE ###\n'
        )
    ) AS final_executive_summary
FROM combined_context;