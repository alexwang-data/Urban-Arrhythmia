<p align="center">
  <img src="https://github.com/alexwang-data/Urban-Arrhythmia/blob/305936b7201e78314a5e64ab9a425fc10da3ded6/MONITOR-ON.png"width="500">
</p>

# Mapping-Urban-Arrhythmia: A Compactness Analysis of New York City Council Districts

## 🌐 Website
https://alexwang-data.github.io/Urban-Arrhythmia/

## 🕵️ Overview
Local representation starts with a map boundary. Urban Arrhythmia is an interactive visualization that translates New York City's 51 council districts into distinct heartbeats. Explore the map to test district boundaries: is that irregular rhythm an oddly drawn border, or just the natural curve of the shoreline?

<p align="center">
  <img src="https://github.com/alexwang-data/Urban-Arrhythmia/blob/900a25d20b7b44cf4bd5c2bbeb7ba397c3a73252/TRIAGE.png"width="500">
</p>

## 📁 Data
U.S. Census; 2020 Decennial Census<br>
https://data.census.gov/

U.S. Census; 2023 American Community Survey 5-Years Estimate<br>
https://data.census.gov/

NYC Department of City Planning; 2023 New York City Council districts<br>
https://www.nyc.gov/content/planning/pages/resources/datasets/city-council

## 📚 Libraries
```r
library(tidycensus)   # for Census API
library(tidyverse)    # for data cleaning and manipulation
library(sf)           # for spatial analysis
library(jsonlite)     # for JSON export
```

<p align="center">
  <img src="https://github.com/alexwang-data/Urban-Arrhythmia/blob/a65ba68edd9d9bb7dab36b68602c41b3f2cf829d/MONITOR-OFF.png"width="500">
</p>

## ⚖️ License

![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC_BY--NC_4.0-lightgrey.svg)

This work is licensed under a
[Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/).

[![CC BY-NC 4.0](https://licensebuttons.net/l/by-nc/4.0/88x31.png)](https://creativecommons.org/licenses/by-nc/4.0/)
