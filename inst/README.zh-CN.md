# asharechips 中文入门

这个包用日线数据估算 A 股筹码成本分布。核心逻辑是每天让旧筹码衰减，再把当天成交的新筹码加进来。模型不能直接观察真实账户，也不能从筹码峰判断某个主力的持仓。

## 安装和第一步

先在 RStudio 安装本地源码包，然后加载：

```r
install.packages("asharechips_0.2.1.tar.gz", repos = NULL, type = "source")
library(asharechips)
chip_mean_cost(c(10, 11, 12), c(50, 20, 30))
```

结果应为 10.8。这就是我们一起学过的“总成本除以总股数”。

## 用虚构数据练习主函数

```r
daily <- data.frame(
  trade_date = c("20260102", "20260105", "20260106"),
  high = c(10, 11, 12), low = c(10, 11, 12), close = c(10, 11, 12),
  vol = c(100, 100, 100), amount = c(100, 110, 120),
  turnover_rate = c(0, 20, 30)
)
chips <- estimate_chip_distribution(daily)
summary(chips)
as.data.frame(chips)
plot(chips)
chips$diagnostics
```

`summary(chips)` 看指标；`as.data.frame(chips)` 看每个价位的筹码；`plot(chips)` 画图；`chips$diagnostics` 看每天的计算过程。

## 接入已有 Tushare 表

你通过自己的账号下载 `daily`、`daily_basic`，以及可选的 `adj_factor`，再交给这个包整理。包本身不下载数据，也不保存 token。

```r
input <- prepare_tushare_data(daily, daily_basic, adj_factor,
                             ts_code = "000001.SZ", as_of = "20260930")
chips <- estimate_chip_distribution(input, adjustment_col = "adj_factor")
```

上面的三个对象须先准备好。日期按股票代码和交易日期一一匹配，缺少指标或复权因子会报错，不会偷偷丢掉日线。

## 最容易错的地方

- `turnover_rate = 5` 表示 5%，不能写成 0.05。
- Tushare 的 `vol` 是手，`amount` 是千元，所以成交均价是 `amount * 10 / vol`。
- 传复权因子时要使用原始未复权价格，避免重复复权。历史价格乘以“当日因子 / 最后一天因子”。
- 默认所有筹码先放在第一天的价格分布中，然后从第二天开始换手。这是初始假设，短历史对结果的影响可能很大。
- 默认指数模型下，换手率 20% 对应的新筹码比例是 `1 - exp(-0.2)`，约 18.13%。它假定随机、均匀替换；想学习最简单的 20% 替换，可设 `turnover_transform = "linear"`。
- 盈利筹码只包含成本低于收盘价的部分，等于收盘价的部分单列为 `breakeven_ratio`。
- `concentration_90` 是成本区间的宽窄指标，数值越小区间越窄；它不表示某个股东的控股比例。

## 进一步的研究与难点

`initial_distribution` 可传入已有的价格和权重表，价格须已经统一到最后交易日口径。这种情况下第一天也会进行换手更新。

```r
initial <- data.frame(price = c(8, 12), weight = c(0.5, 0.5))
chips <- estimate_chip_distribution(daily, initial_distribution = initial)
```

`initialization_weight` 表示初始假设还剩多少；`history_coverage` 表示这些初始权重被模型替换了多少。它们不表示真实股东资料的覆盖率。

日线无法回答“究竟卖掉哪一批旧筹码”。默认算法假设所有旧成本层按同一比例流出，这是最重要的模型限制。解禁、增发、回购也没有自动修正；如有 `float_share` 且发生明显变化，包会提醒你。

`price_method = "uniform"` 会在每天高低价区间内均匀分配新筹码。这种分配是研究假设，日线本身不含成交价格分布。不同模型和 `price_step` 的结果应作敏感性比较，不能只把图画得好看当作模型准确。

详细英文帮助可用 `?estimate_chip_distribution`，可运行的完整教程可用 `vignette("introduction", package = "asharechips")`。
