#!/usr/bin/env python3
"""Reusable visualisation functions for NDVI time-series summaries."""

import matplotlib.pyplot as plt
import pandas as pd


def plot_ndvi_time_series(df, date_col="date", ndvi_col="NDVI", title=None):
    """Plot a long-term NDVI time series."""
    data = df.copy()
    data[date_col] = pd.to_datetime(data[date_col])
    data = data.sort_values(date_col)

    fig, ax = plt.subplots(figsize=(12, 5))
    ax.plot(data[date_col], data[ndvi_col])
    ax.set_xlabel("Date")
    ax.set_ylabel("Mean NDVI")
    ax.set_title(title or "NDVI time series")
    fig.tight_layout()
    return fig, ax


def mean_ndvi_by_observation_period(
    df,
    period_col,
    ndvi_col="NDVI",
    site_col="site",
):
    """Summarise mean NDVI by observation period and study site."""
    required = [period_col, ndvi_col, site_col]
    missing = [column for column in required if column not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    return (
        df.groupby([site_col, period_col], as_index=False)[ndvi_col]
        .mean()
        .rename(columns={ndvi_col: "mean_NDVI"})
    )


def plot_cumulative_ndvi(
    df,
    date_col="date",
    simple_col="NDVI_acc_simple",
    conditional_col="NDVI_acc_conditional",
):
    """Plot simple and conditional cumulative NDVI in separate figures."""
    data = df.copy()
    data[date_col] = pd.to_datetime(data[date_col])
    data = data.sort_values(date_col)

    fig_simple, ax_simple = plt.subplots(figsize=(12, 5))
    ax_simple.plot(data[date_col], data[simple_col])
    ax_simple.set_xlabel("Date")
    ax_simple.set_ylabel("Cumulative NDVI (simple)")
    fig_simple.tight_layout()

    fig_conditional, ax_conditional = plt.subplots(figsize=(12, 5))
    ax_conditional.plot(data[date_col], data[conditional_col])
    ax_conditional.set_xlabel("Date")
    ax_conditional.set_ylabel("Cumulative NDVI (conditional)")
    fig_conditional.tight_layout()

    return (fig_simple, ax_simple), (fig_conditional, ax_conditional)
