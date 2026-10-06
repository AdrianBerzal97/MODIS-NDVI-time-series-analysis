#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""NDVI accumulation methods used in the study.

Methods
-------
1. Simple cumulative NDVI.
2. Conditional cumulative NDVI.

Accumulations are reset at the beginning of each hydrological year.
The hydrological year starts in September.
"""

import numpy as np
import pandas as pd


def add_hydrological_year(df, date_col="date", start_month=9):
    """Add a hydrological-year identifier to a data frame."""
    data = df.copy()
    data[date_col] = pd.to_datetime(data[date_col])
    data["hydrological_year"] = np.where(
        data[date_col].dt.month >= start_month,
        data[date_col].dt.year + 1,
        data[date_col].dt.year,
    )
    return data


def simple_cumulative_ndvi(values):
    """Return the cumulative sum of NDVI observations."""
    return values.cumsum()


def conditional_cumulative_ndvi(values):
    """Accumulate NDVI only when the current value is >= the previous value."""
    values = values.to_numpy(dtype=float)
    cumulative = np.zeros(len(values))

    if len(values) == 0:
        return cumulative

    cumulative[0] = values[0]

    for i in range(1, len(values)):
        if values[i] >= values[i - 1]:
            cumulative[i] = cumulative[i - 1] + values[i]
        else:
            cumulative[i] = cumulative[i - 1]

    return cumulative


def calculate_ndvi_accumulations(df, date_col="date", ndvi_col="NDVI"):
    """Calculate both accumulation metrics independently by hydrological year."""
    data = add_hydrological_year(df, date_col=date_col)
    data = data.sort_values(["hydrological_year", date_col])

    output = []
    for _, group in data.groupby("hydrological_year"):
        group = group.copy()
        group["NDVI_acc_simple"] = simple_cumulative_ndvi(group[ndvi_col])
        group["NDVI_acc_conditional"] = conditional_cumulative_ndvi(
            group[ndvi_col]
        )
        output.append(group)

    if not output:
        return data.assign(
            NDVI_acc_simple=pd.Series(dtype=float),
            NDVI_acc_conditional=pd.Series(dtype=float),
        )

    return pd.concat(output, ignore_index=True)
