import socket
import numpy as np
import pandas as pd 
from sklearn import datasets
from sklearn.linear_model import SGDClassifier
import MetaTrader5 as mt5



class socketserver:
    def __init__(self, address = '', port = 9090):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.address = address
        self.port = port
        self.sock.bind((self.address, self.port))
        self.cummdata = ''
        
    def recvmsg(self):
        self.sock.listen(1)
        self.conn, self.addr = self.sock.accept()
        print('connected to', self.addr)
        self.cummdata = ''

        while True:
            data = self.conn.recv(10000)
            self.cummdata+=data.decode("utf-8")
            if not data:
                break
            data = self.cummdata.split()
            data = list(map(int, data))
            data = np.array(data)
            data = data.reshape(1,-1)
            data = pd.DataFrame(data, columns=['A', 'B', 'C', 'D','E', 'F', 'G', 'H','I'])
            print(data)
            pred = dtc.predict(data)
            print(pred)
            if (pred == 0): Buy()
            if(pred == 1): Sell()
            # self.conn.send(bytes(pred, "utf-8"))
            return self.cummdata
            
    def __del__(self):
        self.sock.close()


dataframe = pd.read_csv(r"C:/Users/ramin/AppData/Roaming/MetaQuotes/Terminal/Common/Files/EURUSD30min300TP.csv",delimiter="\t", encoding="UTF-16")
dataframe.columns=['A', 'B', 'C', 'D','E', 'F', 'G', 'H','I','target']
target = dataframe['target']
print(dataframe)

dataframe1 = dataframe.drop(columns=['target'])
dataframe2 = dataframe1.values
from sklearn.model_selection import train_test_split
x_train , x_test, y_train, y_test = train_test_split(dataframe1, target, test_size=.3,random_state=23 )      #,stratify='yes' random_state=23

# Decision Tree
from sklearn.tree import DecisionTreeClassifier
from sklearn import metrics
dtc = DecisionTreeClassifier()
dtc.fit(x_train, y_train)
predict_dtc = dtc.predict(x_test)
print("DTC SCORE : ",metrics.accuracy_score(y_test, predict_dtc),"\n")

from sklearn.metrics import confusion_matrix, classification_report
print(confusion_matrix(y_test, predict_dtc))
print(classification_report(y_test, predict_dtc))

from sklearn.tree import DecisionTreeClassifier
from sklearn.tree import export_text
y = target.values
decision_tree = DecisionTreeClassifier(random_state=0, max_depth=2)
decision_tree = decision_tree.fit(dataframe2, y)
r = export_text(decision_tree, feature_names=['A', 'B', 'C', 'D','E', 'F', 'G', 'H','I'])
print(r)

# connect to MetaTrader 5
if not mt5.initialize():
    print("initialize() failed")
    mt5.shutdown()
    
# request connection status and parameters
print(mt5.terminal_info())
# get data on MetaTrader 5 version
print(mt5.version())

serv = socketserver('127.0.0.1', 9090)
symbol  = "EURUSD"
lot     = 0.01
tp      = 300


def Start():
    while True:  

        msg = serv.recvmsg()
        # msg = int(msg)
        # print("1 : ",msg)
        # msg = np.array(msg)
        # print("2 : ",msg)
        # pred = dtc.predict(msg)
        # if(pred == 0): Buy()
        # if(pred == 1): Sell()





 
# prepare the buy request structure
def Buy():
    point = mt5.symbol_info(symbol).point
    price = mt5.symbol_info_tick(symbol).ask
    deviation = 20
    request = {
        "action": mt5.TRADE_ACTION_DEAL,
        "symbol": symbol,
        "volume": lot,
        "type": mt5.ORDER_TYPE_BUY,
        "price": price,
        "sl": price - tp * point,
        "tp": price + tp * point,
        "deviation": deviation,
        "magic": 234000,
        "comment": "python script open",
        "type_time": mt5.ORDER_TIME_GTC,
        "type_filling": mt5.ORDER_FILLING_RETURN,
    }
    
    # send a trading request
    result = mt5.order_send(request)
    # check the execution result
    print("1. order_send(): by {} {} lots at {} with deviation={} points".format(symbol,lot,price,deviation));
    print("2. order_send done, ", result)
    print("   opened position with POSITION_TICKET={}".format(result.order))
    print("   sleep 2 seconds before closing position #{}".format(result.order))


# prepare the sell request structure
def Sell():
    point = mt5.symbol_info(symbol).point
    price = mt5.symbol_info_tick(symbol).bid
    deviation = 20
    request = {
        "action": mt5.TRADE_ACTION_DEAL,
        "symbol": symbol,
        "volume": lot,
        "type": mt5.ORDER_TYPE_SELL,
        "price": price,
        "sl": price + tp * point,
        "tp": price - tp * point,
        "deviation": deviation,
        "magic": 234000,
        "comment": "python script open",
        "type_time": mt5.ORDER_TIME_GTC,
        "type_filling": mt5.ORDER_FILLING_RETURN,
    }
    
    # send a trading request
    result = mt5.order_send(request)
    # check the execution result
    print("1. order_send(): by {} {} lots at {} with deviation={} points".format(symbol,lot,price,deviation));
    print("2. order_send done, ", result)
    print("   opened position with POSITION_TICKET={}".format(result.order))
    print("   sleep 2 seconds before closing position #{}".format(result.order))



if __name__ == '__main__':
    #while True:
        Start()
