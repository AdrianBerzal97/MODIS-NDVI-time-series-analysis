#!/usr/bin/env python3
"""Utilities for preparing long-term NDVI time series for analysis."""

import numpy as np
import pandas as pd


def add_hydrological_year(df, date_col="date", start_month=9):
    """Assign each observation to a hydrological year beginning in September."""
    data = df.copy()
    data[date_col] = pd.to_datetime(data[date_col])
    data["hydrological_year"] = np.where(
        data[date_col].dt.month >= start_month,
        data[date_col].dt.year + 1,
        data[date_col].dt.year,
    )
    return data


def prepare_ndvi_time_series(
    df,
    date_col="date",
    ndvi_col="NDVI",
    site_col=None,
    start_month=9,
):
    """Clean and chronologically organise an NDVI time series."""
    data = df.copy()
    data[date_col] = pd.to_datetime(data[date_col], errors="coerce")
    data[ndvi_col] = pd.to_numeric(data[ndvi_col], errors="coerce")
    data = data.dropna(subset=[date_col, ndvi_col])

    data = add_hydrological_year(
        data,
        date_col=date_col,
        start_month=start_month,
    )

    sort_cols = [date_col]
    if site_col is not None and site_col in data.columns:
        sort_cols = [site_col, date_col]

    return data.sort_values(sort_cols).reset_index(drop=True)
