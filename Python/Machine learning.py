import numpy as np
import pandas as pd 
import matplotlib.pyplot as plt
from sklearn import datasets
from sklearn.linear_model import SGDClassifier


dataframe = pd.read_csv(r"C:/Users/Ramin/AppData/Roaming/MetaQuotes/Terminal/Common/Files/EURUSD15min100TP.csv",delimiter="\t", encoding="UTF-16")
dataframe.columns=['A', 'B', 'C', 'D','E', 'F', 'G', 'H','I','target']
target = dataframe['target']
print(dataframe)

dataframe1 = dataframe.drop(columns=['target'])
dataframe2 = dataframe1.values
from sklearn.model_selection import train_test_split
x_train , x_test, y_train, y_test = train_test_split(dataframe1, target, test_size=.3, random_state=42)
print(y_train.shape, "\n")

# KMeans ALgo
from sklearn.neighbors import KNeighborsClassifier
knn = KNeighborsClassifier(n_neighbors=6, metric='minkowski', p=3)
knn.fit(x_train, y_train)
labels = knn.predict(x_test)
print("KNN SCORE : ",knn.score(x_test,y_test))


# Decision Tree
from sklearn.tree import DecisionTreeClassifier
from sklearn import metrics
dtc = DecisionTreeClassifier()
dtc.fit(x_train, y_train)
predict_dtc = dtc.predict(x_test)
print("DTC SCORE : ",metrics.accuracy_score(y_test, predict_dtc),"\n")


# Cross Validation for Decision tree and KMEANS ALgo
from sklearn.model_selection import cross_val_score
cv_score_dtc = cross_val_score(dtc, x_train, y_train, cv= 10)
print("CV SCORE for DTC : ",cv_score_dtc)
print()
cv_score_knn = cross_val_score(knn, x_train, y_train, cv= 10)
print("CV SCORE for KNN : ",cv_score_knn)



# LASSO  (feature selection)
from sklearn.linear_model import Lasso
lasso = Lasso(alpha=0.1, normalize=True)
lasso.fit(x_train, y_train)

print(lasso.coef_)