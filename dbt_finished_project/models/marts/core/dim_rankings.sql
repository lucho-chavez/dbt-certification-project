{{
    config(
        materialized='incremental',
        unique_key='ranking_key'
    )
}}

with boardgames_filtered as (
    select * from {{ ref('int_boardgames__boardgames_filtered') }}
),

rankings as (
    select * from {{ ref('stg_boardgames__rankings') }}
),

dim_rankings as (
    select
        ranking_key,
        {{ dbt_utils.generate_surrogate_key(['rankings.boardgame_id']) }} as boardgame_key,
        boardgame_rank,
        boardgame_total_reviews,
        boardgame_url,
        boardgame_thumbnail,
        updated_at,
        valid_from,
        valid_to,
        is_current

    from rankings
    where boardgame_id in (select boardgame_id from boardgames_filtered)
)

select * from dim_rankings

{% if is_incremental() %}

  -- this filter will only be applied on an incremental run
  -- (uses >= to include records arriving later on the same day as the last run of this model)
  where updated_at > (select max(updated_at) from {{ this }})

{% endif %}