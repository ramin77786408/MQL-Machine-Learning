from autots import AutoTS
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import MetaTrader5 as mt5

# establish connection to MetaTrader 5 terminal
if not mt5.initialize():
    print("initialize() failed, error code =",mt5.last_error())
    quit()
 
# get 10 GBPUSD D1 bars from the current day
rates = mt5.copy_rates_from_pos("EURUSD", mt5.TIMEFRAME_M15, 0, 1000)
df = pd.DataFrame(rates)
close = df['close']
# shut down connection to the MetaTrader 5 terminal
mt5.shutdown()
# print(close)


from sktime.forecasting.model_selection import temporal_train_test_split
from sktime.performance_metrics.forecasting import mean_absolute_percentage_error
from sktime.regression.deep_learning import CNNRegressor
from sktime.utils.plotting import plot_series

plot_series(close)

y_train, y_test = temporal_train_test_split(close,train_size=0.8)

model = CNNRegressor(n_epochs=100,batch_size=32,kernel_size=10)
model.fit()





forecaster = ThetaForecaster(sp=12)  # monthly seasonal periodicity
forecaster.fit(y_train)
y_pred = forecaster.predict(fh)
mean_absolute_percentage_error(y_test, y_pred)



# # make data
# x = np.arange(1000)
# y = df['close']
# # plot
# fig, ax = plt.subplots()
# ax.plot(x, y, linewidth=1.5)
# plt.show()