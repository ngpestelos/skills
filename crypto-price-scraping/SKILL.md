---
name: crypto-price-scraping
version: 1.0
description: Scrape live cryptocurrency prices and market data using firecrawl from CoinMarketCap or similar sources. Extracts top cryptocurrencies, prices, market cap, and 24h/7d performance.
trigger: cryptocurrency prices, crypto prices, bitcoin price, ethereum price, market cap, coinmarketcap, scrape crypto, top 10 crypto
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
---

# Cryptocurrency Price Scraping

> **Purpose:** Extract live cryptocurrency prices and market data from CoinMarketCap using firecrawl.

## Quick Start

```bash
# Scrape CoinMarketCap homepage
export FIRECRAWL_API_KEY=$(grep "FIRECRAWL_API_KEY" ~/.hermes/profiles/belvedere/.env | cut -d'=' -f2)
python3 .claude/scripts/firecrawl-fetch.py scrape "https://coinmarketcap.com" -o .firecrawl/crypto.md
```

## Extract Top 10 Cryptocurrencies

After scraping, extract the price table:

```bash
# Find the price table lines
grep -n -E "(BTC|ETH|Bitcoin|Ethereum|Price|Market Cap)" .firecrawl/crypto.md | head -30

# Read the table section (usually around line 331)
read_file .firecrawl/crypto.md offset=331 limit=30
```

## Format as Markdown Table

Example output structure:

```markdown
| Rank | Name | Symbol | Price | 24h % | 7d % | Market Cap |
|------|------|--------|-------|-------|------|------------|
| 1 | Bitcoin | BTC | $69,168.02 | +3.09% | +2.55% | $1.38T |
| 2 | Ethereum | ETH | $2,131.62 | +3.75% | +4.28% | $257.27B |
```

## Include Market Overview

Also extract market metrics:

```markdown
| Metric | Value |
|--------|-------|
| Global Market Cap | $2.37T (+2.38%) |
| Fear & Greed Index | 36 (Fear) |
| Bitcoin Dominance | 58.45% |
```

## Save to PARA Vault

Follow YYYYMMDD conventions:

```
2 Resources/YYYYMMDD Crypto Prices.md
```

Example filename: `20260406 Crypto Prices.md`

## Alternative Sources

| Source | URL | Notes |
|--------|-----|-------|
| CoinMarketCap | https://coinmarketcap.com | Most comprehensive |
| CoinGecko | https://coingecko.com | Alternative data |
| Binance | https://binance.com/en/markets | Exchange prices |

## Troubleshooting

**Empty or partial data:**
- CoinMarketCap may block scraping; try `--wait-for 3000` flag
- Check if JavaScript rendered content is captured

**API key errors:**
- See `hermes-profile-credential-resolution` skill for credential setup

**Data format changed:**
- CoinMarketCap updates their HTML structure periodically
- Adjust grep/offset values based on current page structure
