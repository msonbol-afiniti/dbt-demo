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


/*
    Uncomment the line below to remove records with null `id` values
*/

-- where id is not null
