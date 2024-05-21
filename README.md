Welcome to your new dbt project!  

### Using the starter project  

Try running the following commands:  
- dbt run  
- dbt test  
  
  
### Resources:  
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)  
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers  
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support  
- Find [dbt events](https://events.getdbt.com) near you  
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices  
  

### Steps
**1- create a virutal environment**  
```shell
python -m venv dbt-env              # create the environment  
```

**2- activate the virtual environment**  
```shell
dbt-env\Scripts\activate            # activate the environment for Windows  
```

**3- install dbt and postgres adaptor**   
```shell
python -m pip install dbt-core dbt-postgres  
```

**4- validate installation**  
```shell
dbt --version  
```

**5- initialize a dbt project and follow the prompt**   
```shell
dbt init
```  

**6- change dbt environment file to point to local profiles.yml instead of default one in user directory**
```shell
$env:DBT_PROFILES_DIR="C:\Users\mina.sonbol\Documents\dbt_projects\dbt_demo_1"
```

**7- encrypt password**   
```shell
$env:DB_PASSWORD = "sample_password"  
echo $env:DB_PASSWORD  
# change password to ${DB_PASSWORD} in profiles.yml  
```

**8- create the profile.yml file in the project directory or the user's home directory and setup the db connection**   
```shell
dbt init my-project
```

```yaml
my_dbt_demo:  
  outputs:   
    my_dev_db:  
      type: postgres  
      host: localhost  
      port: 5432  
      user: sample_user  
      pass: ${DB_PASSWORD}  
      dbname: new_sample_db  
      schema: dev  
      threads: 1  
        
    my_prod_db:  
      type: postgres  
      host: localhost  
      port: 5432  
      user: sample_user  
      pass: ${DB_PASSWORD}  
      dbname: new_sample_db  
      schema: prod  
      threads: 1  
```
 
**9- test connection**  
dbt debug --target my_dev_db  
dbt debug --target my_prod_db  

**10- double check the profile used in the dbt_project.yml file, and add the models under the models section**
```yml

# Name your project! Project names should contain only lowercase characters
# and underscores. A good package name should reflect your organization's
# name or the intended use of these models
name: 'dbt_demo_1'
version: '1.0.0'

# This setting configures which "profile" dbt uses for this project.
profile: 'dbt_demo_1'

# These configurations specify where dbt should look for different types of files.
# The `model-paths` config, for example, states that models in this project can be
# found in the "models/" directory. You probably won't need to change these!
model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

clean-targets:         # directories to be removed by `dbt clean`
  - "target"
  - "dbt_packages"


# Configuring models
# Full documentation: https://docs.getdbt.com/docs/configuring-models

# In this example config, we tell dbt to build all models in the example/
# directory as views. These settings can be overridden in the individual model
# files using the `{{ config(...) }}` macro.
models:
  dbt_demo_1:
    # Config indicated by + and applies to all files under models/example/
    staging:
      +materialized: table
    core:
      +materialized: table
    reporting:
      +materialized: table
      +docs:
          node_color: "red"
```
**11- create a new folder under models called staging**  

**12- create a new file under staging called schema.yml, and define the source tables**
```yaml
version: 2

sources:
  - name: staging
    database: new_sample_db
    schema: dev

    # loaded_at_field: record_loaded_at
    tables:
      - name: callrecords
      - name: outcomes

models:
  - name: stg_callrecords
    description: ""
  - name: stg_outcomes
    description: ""
```
**13- create a new file called stg_callrecords.sql under the staging folder**
```sql
{{ config(materialized='table') }}

with cte_callrecords as (
    select 
        *,
        row_number() over (partition by call_id::int) as rn 
    from {{ source('staging', 'callrecords') }}
    where starttime is not null
)
select
    -- identifiers
    cast(call_id as integer) as call_id,
    cast(emp_id as integer) as emp_id,
    cast(cust_id as varchar(5)) as cust_id,
    -- benchmark
    cast(benchmark as integer) as benchmark,
    -- agent site
    cast(agent_site as varchar(5)) as agent_site,
    -- timestamps
    cast(starttime as timestamp) as starttime,
    cast(endtime as timestamp) as endtime,
    now() as insert_time
from cte_callrecords
where rn = 1

-- dbt build --select <model.sql> --vars '{'is_test_run: false}'
{% if var('is_test_run', default=true) %}

  limit 100

{% endif %}
``` 
**14- create a new file called stg_outcomes.sql under the staging folder**
```sql
{{ config(materialized='table') }}

with cte_outcomes as (
    select *
    from {{ source('staging', 'outcomes') }}
)
select 
    -- identifiers
    cast(sale_id as integer) as sale_id,
    cast(emp_id as integer) as emp_id,
    cast(cust_id as varchar(5)) as cust_id,
    -- outcome
    cast(sale_flag as integer) as sale_flag,
    -- timestamps
    cast(sale_time as timestamp) as sale_time,
    now() as insert_time
from cte_outcomes

-- dbt build --select <model.sql> --vars '{'is_test_run: false}'
{% if var('is_test_run', default=true) %}

  limit 100

{% endif %}
```
**15- create a new folder under models callded core**  

**16- create a new file called schema.yml under the core folder**
```yaml
version: 2

models:
  - name: aca
    description: ""
  - name: vaca
    description: ""
```
**17- create a new file called aca.sql under the core folder"
```sql
{{ config(materialized='table') }}
with cte_calls as (
    select c.*
    from {{ ref('stg_callrecords') }} c 
), cte_outcomes as (
    select s.*
    from {{ ref('stg_outcomes') }} s 
)
    select 
        c.*, 
        s.sale_id , 
        s.sale_flag , 
        s.sale_time 
    from cte_calls c 
    left join cte_outcomes s 
    on c.emp_id = s.emp_id 
    and c.cust_id = s.cust_id 
    and s.sale_time >= c.starttime and s.sale_time <= c.endtime 

-- dbt build --select <model.sql> --vars '{'is_test_run: false}'
{% if var('is_test_run', default=true) %}

  limit 100

{% endif %}
```
**18- create a new file called vaca.sql under the core folder**
```sql
{{ config(materialized='view') }}
select *
from {{ref('aca')}}

-- dbt build --select <model.sql> --vars '{'is_test_run: false}'
{% if var('is_test_run', default=true) %}

  limit 100

{% endif %}
```
**19- create a new directory called reporting under models**  

**20- create a new file called schema.yml under the reporting folder**
```yml
version: 2

models:
  - name: portal
    description: ""
  - name: site_analysis
    description: ""
  - name: site_analysis_pivot
    description: ""
```
**21- create a new file called portal.sql under the reporting folder**
```sql
{{ config(materialized='view') }}

with cte_aca as (
    select 
        *
    from {{ ref('aca') }} aca
), cte_portal as (
    select
        date_trunc('day',starttime)::date as calldate, 
    	sum(case when benchmark=1 then 1 else 0 end) as on_calls ,
    	sum(case when benchmark=0 then 1 else 0 end) as off_calls ,
    	sum(case when benchmark=1 then sale_flag else 0 end) on_sales,
    	sum(case when benchmark=0 then sale_flag else 0 end) off_sales
    from cte_aca
    group by 1
), cte_incr as (
    select 
    	calldate,
    	on_calls,
    	off_calls,
    	on_calls+off_calls as total_calls,
    	on_sales,
    	off_sales,
    	on_sales+off_sales as total_sales,
    	on_sales::float / on_calls::float as on_spc,
    	off_sales::float / off_calls::float as off_spc,
    	((on_sales::float / on_calls::float)-(off_sales::float / off_calls::float)) as lift,
    	((on_sales::float / on_calls::float)-(off_sales::float / off_calls::float))*on_calls::float as incremental
    from cte_portal
)
select * 
from cte_incr

-- dbt build --select <model.sql> --vars '{'is_test_run: false}'
{% if var('is_test_run', default=true) %}

  limit 100

{% endif %}
```
**22- create a new file called site_analysis.sql under the reporting folder**
```sql
{{ config(materialized='view') }}

with cte_aca as (
    select 
        *
    from {{ ref('aca') }} aca
), cte_portal as (
    select
        date_trunc('day',starttime)::date as calldate, 
        agent_site,
    	sum(case when benchmark=1 then 1 else 0 end) as on_calls ,
    	sum(case when benchmark=0 then 1 else 0 end) as off_calls ,
    	sum(case when benchmark=1 then sale_flag else 0 end) on_sales,
    	sum(case when benchmark=0 then sale_flag else 0 end) off_sales
    from cte_aca
    group by 1, 2
), cte_incr as (
    select 
    	calldate,
        agent_site,
    	on_calls,
    	off_calls,
    	on_calls+off_calls as total_calls,
    	on_sales,
    	off_sales,
    	on_sales+off_sales as total_sales,
    	coalesce(on_sales::float / nullif(on_calls::float, 0), 0) as on_spc,
    	coalesce(off_sales::float / nullif(off_calls::float, 0), 0) as off_spc,
    	coalesce(((on_sales::float / nullif(on_calls::float, 0))-(off_sales::float / nullif(off_calls::float, 0))), 0) as lift,
    	coalesce(((on_sales::float / nullif(on_calls::float, 0))-(off_sales::float / nullif(off_calls::float, 0)))*on_calls::float, 0)::float as incremental
    from cte_portal
)
select * 
from cte_incr

-- dbt build --select <model.sql> --vars '{'is_test_run: false}'
{% if var('is_test_run', default=true) %}

  limit 100

{% endif %}
```
**23- create a new file called site_analysis_pivot.sql under the reporting folder**
```sql
{% set categories = dbt_utils.get_column_values(ref('site_analysis'), 'calldate') %}

with pivoted_view as (
    select 
        agent_site,
        {{ dbt_utils.pivot(
            'calldate',
            categories,
            agg='array_agg',
            then_value='incremental',
            else_value='NULL') }}
    from {{ ref('site_analysis') }}
    group by 1
)
select 
    agent_site,
    {% for category in categories %}
    (array_remove("{{ category }}",NULL))[1] as "{{ category }}"
    {% if not loop.last %}, {% endif %}
    {%endfor%}
from pivoted_view

-- dbt build --select <model.sql> --vars '{'is_test_run: false}'
{% if var('is_test_run', default=true) %}

  limit 100

{% endif %}
```

**24- run dbt commands**
```shell
dbt build
dbt docs generate
dbt docs serve
```

**25- add documentation to staging's schema.yml**
```yml
version: 2

sources:
  - name: staging
    database: new_sample_db
    schema: dev

    # loaded_at_field: record_loaded_at
    tables:
      - name: callrecords
        description: >
          Call records data containing a detailed record that is generated for each call that arrives at a peripheral Contact Center environment. 
          The TCD record contains comprehensive information about the call, including customer and agent IDs, start time, end time, and agent site.
          Benchmark data is appended to the call record data by the client and shared in the same CSV file. 
          Data is shared daily as a csv file with 7 columns.
      
      - name: outcomes
        description: >
          Sales records as generated by the point-of-sale system for each sale interaction. The interaction may or may not end in an actual.
          A sale record should always have a unique identifier and should be attributed to an agent through the emp_id, and to a customer through cust_id.
          The sale flag indicates whether the sale interaction ended in a sale or not. This will be used as our binomial metric.
          Data is shared daily as a csv file with 5 columns.

models:
  - name: stg_callrecords
    description: >
      Staging of the call records data where the data is type case to its correct format as illustrated below in the column data types,
      and an insert_date column is created to indicate when the data was staged. 
    columns:
      - name: call_id
        data_type: integer
        description: Primary key for this table, generated by the peripheral switch system

      - name: emp_id
        data_type: integer
        description: The ID of the agent that answered the call 

      - name: cust_id
        data_type: character varying
        description: The ID of the customer who made the call 

      - name: benchmark
        data_type: integer
        description: Afiniti benchmark appended by the client

      - name: starttime
        data_type: timestamp without time zone
        description: Call start time

      - name: endtime
        data_type: timestamp without time zone
        description: Call end time

      - name: agent_site
        data_type: character varying
        description: >
          A code indicating the agent site that received the call
          A = Northeast
          B = Southeast
          C = Midwest     
          D = Southwest
          E = West Coast

  - name: stg_outcomes
    description: >
      Staging of the outcomes data where the data is type case to its correct format as illustrated below in the column data types, 
      and an insert_date column is created to indicate when the data was staged. 
    columns:
      - name: sale_id
        data_type: integer
        description: Primary key for this table, generated by point-of-sale system to identify sale

      - name: emp_id
        data_type: integer
        description: The ID of the agent that answered the call 

      - name: cust_id
        data_type: character varying
        description: The ID of the customer who made the call 

      - name: sale_flag
        data_type: integer
        description: The sale flag indicates whether an interaction ended in a sale (1) or not (0). All interactions must have a sale_flag value

      - name: sale_time
        data_type: timestamp without time zone
        description: The timestamp of the sale interaction
```

**26- add unit tests to staging's schema.yml: freshness test**
```yml
# line 24        
        freshness:
          warn_after: {count: 3, period: minute}
          # error_after: {count: 6, period: hour}
        loaded_at_field: sale_time::timestamp
```
Note: Freshness can be tested on database and tables, with or without a loaded_at_field.

**27- add unit tests to staging's schema.yml: primary key test**
```yml
# line 38
        data_tests:
          - unique:
              severity: warn
          - not_null:
              severity: error
              # severity: warn
```

**28- add unit tests to staging's schema.yml: accepted values**
```yml
# line 80
        data_tests:
          - accepted_values:
              values: ['A','B','C','D','E']
              severity: warn
```

**29- version control with git**  

**30- run with test_vars set to false, and deploy to prod**
```shell
```

### git commands  
echo "# dbt-demo" >> README.md  
git init  
git add README.md  
git commit -m "first commit"  
git branch -M main  
git remote add origin https://github.com/msonbol-afiniti/dbt-demo.git  
git push -u origin main  
  

### dbt commands  
dbt build  
dbt test  
dbt run  
dbt docs generate  
dbt docs serve  

