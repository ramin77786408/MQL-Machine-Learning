import tensorflow as tf
import cryptowatch as cw
import pandas as pd
import numpy as np
keras = tf.keras
import matplotlib.pyplot as plt
# %matplotlib inline

windows_size=16
split_ratio = 0.8
tf.random.set_seed(42)
np.random.seed(42)
batch_size = 32
def window_dataset(series, window_size, batch_size=32, shuffle_buffer=1000):
    dataset = tf.data.Dataset.from_tensor_slices(series)
    dataset = dataset.window(window_size, shift=4, drop_remainder=True)
    dataset = dataset.flat_map(lambda window: window.batch(window_size))
    dataset = dataset.map(lambda window: (window[:-4], window[-3:-1]))
    dataset = dataset.shuffle(shuffle_buffer)
    dataset = dataset.batch(batch_size).prefetch(1)
    return dataset

def model_forecast(model, series, window_size):
    ds = tf.data.Dataset.from_tensor_slices(series)
    ds = ds.window(window_size-4, shift=4, drop_remainder=True)
    ds = ds.flat_map(lambda w: w.batch(window_size-4))
    ds = ds.batch(batch_size).prefetch(1)
    return model.predict(ds)

def seq2seq_window_dataset(series, window_size, batch_size=32, shuffle_buffer=1000):
    series= tf.expand_dims(series, axis=-1)
    ds = tf.data.Dataset.from_tensor_slices(series)
    ds = ds.window(window_size, shift=4, drop_remainder=True)
    ds = ds.flat_map(lambda window: window.batch(window_size))
    ds = ds.shuffle(shuffle_buffer)
    ds = ds.map(lambda w: (w[:-4], w[4:]))
    return ds.batch(batch_size).prefetch(1)


candles = cw.markets.get("kraken:btcusd", ohlc=True)
df = pd.DataFrame(candles.of_5m,columns=["close_timestamp", "open", "high", "low", "close", "volume_base", "volume_quote"])
df1 = df.drop(["close_timestamp","volume_base","volume_quote"], axis=1)

df2 = df1.values
df3 = np.reshape(df2,-1)


split = int(split_ratio*len(df3))
train = df3[:split]
valid = df3[split:]
print("train: ", len(train))
print("valid: ", len(valid))
train_set = window_dataset(train, windows_size,shuffle_buffer=len(train), batch_size=batch_size)
valid_set = window_dataset(valid, windows_size,shuffle_buffer=len(valid), batch_size=batch_size)
print(train.shape)

# Dense Model
model = keras.models.Sequential([
    keras.layers.Dense(12, input_shape=[windows_size-4]),
    keras.layers.Dense(2)
])
# end Dense Model

# # RNN Model
# model = keras.models.Sequential([
#     keras.layers.Lambda(lambda x: tf.expand_dims(x, axis=-1), input_shape=[None]),
#     keras.layers.SimpleRNN(120, return_sequences=True),
#     keras.layers.SimpleRNN(120),
#     keras.layers.Dense(2),
#     keras.layers.Lambda(lambda x: x * 200.0)
# ])
# # End RNN Model

# # Back Propagation RNN Model
# train_set = seq2seq_window_dataset(train,windows_size,batch_size=128)
# valid_set = seq2seq_window_dataset(valid,windows_size,batch_size=128)
#
# model = keras.models.Sequential([
#     keras.layers.SimpleRNN(120, return_sequences=True, input_shape=[None,1]),
#     keras.layers.SimpleRNN(120, return_sequences=True),
#     keras.layers.Dense(2),
#     keras.layers.Lambda(lambda x: x * 200.0)
# ])
# # End Back Propagation RNN Model

# # CONV1D Model
# train_set = seq2seq_window_dataset(train,windows_size,batch_size=128)
# valid_set = seq2seq_window_dataset(valid,windows_size,batch_size=128)
#
# model = keras.models.Sequential([
#     keras.layers.Conv1D(filters=32, kernel_size=5, strides=1, padding="causal", activation="relu",
#                         input_shape=[None, 1]),
#     keras.layers.LSTM(32, return_sequences=True),
#     keras.layers.LSTM(32, return_sequences=True),
#     keras.layers.Dense(2),
#     keras.layers.Lambda(lambda x: x * 200)
# ])
# # End CONV1D Model

optimizer = keras.optimizers.SGD(lr=1e-9, momentum=0.9)
model.compile(loss=keras.losses.Huber(),
              optimizer=optimizer,
              metrics=["mae"])
early_stopping = keras.callbacks.EarlyStopping(patience=10)
model_checkpoint = keras.callbacks.ModelCheckpoint("my_checkpoint.h5", save_best_only=True)

model.fit(train_set, epochs=500, validation_data=valid_set, callbacks=[early_stopping])

# lr_schedule = keras.callbacks.LearningRateScheduler(
#     lambda epoch:1e-6 * 100 ** (epoch/30)
# )
# history = model.fit(train_set, epochs=100, callbacks=[lr_schedule])
# plt.semilogx(history.history["lr"], history.history["loss"])
# plt.axis([1e-6, 1e-3, 0, 1000])
# plt.show()

# model = keras.models.load_model("my_checkpoint.h5")

last_data = df3[-12:]
# print(df3[-16:])
# print(last_data)
forecast = model_forecast(model, last_data, windows_size)
print(forecast)