# Multi-region, horizontally autoscaled Cantaloupe IIIF server

https://cantaloupe.libops.io/iiif/2

## How it works

The cantaloupe IIIF server is running in multiple Google Cloud regions. Any requests will route to the region closest to the client request (though if your nearest region is experiencing an outage, your request will route to an available region).

You can pass any publicly available URL to the cantaloupe IIIF server. e.g. for a 80x120 px JPG of a dog use

```
https://cantaloupe.libops.io/iiif/2/https%3A%2F%2Ffastly.picsum.photos%2Fid%2F237%2F200%2F300.jpg%3Fhmac%3DTmmQSbShHz9CdQm0NkEjx1Dyh_Y984R9LpNrpvH2D_U/full/80,120/0/default.jpg
```

## Regions available


| Region Name                 | City/Area                   |
|-----------------------------|-----------------------------|
| **us-east4**                | Ashburn, Virginia           |
| **us-east5**                | Columbus, Ohio              |
| **us-central1**             | Council Bluffs, Iowa        |
| **us-west3**                | Salt Lake City, Utah        |
| **us-west1**                | The Dalles, Oregon          |
| **us-west4**                | Las Vegas, Nevada           |
| **us-south1**               | Dallas, Texas               |
| **northamerica-northeast1** | Montréal, Québec, Canada    |
| **northamerica-northeast2** | Toronto, Ontario, Canada    |
| **australia-southeast1**    | Sydney, New South Wales     |
| **australia-southeast2**    | Melbourne, Victoria         |

## Usage

This is free to try. Please contact `info at libops dot io` for pricing information.

## Install (Islandora)

To use these managed service, in your ISLE `docker-compose.yml` you can point to the respective service to have it perform your derivative generation.

```
    drupal-prod:
        <<: [*prod, *drupal]
        environment:
            <<: [*drupal-environment]
            DRUPAL_DEFAULT_CANTALOUPE_URL: "https://cantaloupe.libops.io/iiif/2"
```


## Monitoring

A VALE dashboard for this service **will be** available at https://www.libops.io/cantaloupe
