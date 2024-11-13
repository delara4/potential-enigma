import pandas as pd  # For handling data and creating DataFrames
import numpy as np  # For numerical operations and array manipulation
from sklearn.model_selection import train_test_split  # For splitting data into training and test sets
from sklearn.neighbors import KNeighborsClassifier  # For implementing the K-Nearest Neighbors classifier
from sklearn.metrics import accuracy_score  # For calculating the accuracy of the model
from sklearn.preprocessing import StandardScaler  # For normalizing the data (Z-score normalization)
from sklearn.decomposition import PCA  # For applying PCA to reduce dimensionality

dataFrame = pd.read_csv('iris.csv')  # Getting the dataset into a dataframe

# -PREPROCESSING-

# 4 Features
X = dataFrame.drop(['species'], axis=1).values  # Input variables (features)
y = dataFrame['species'].values  # Output variable (target)

# Initialize the scaler
scaler = StandardScaler()  # Used for normalizing features (Z-score normalization)
# Normalization via Z-score
X_normalized = scaler.fit_transform(X)  # Apply normalization to the feature set

# Split the data
X_train, X_test, y_train, y_test = train_test_split(X_normalized, y, test_size=0.3, random_state=42)  # Train-test split with 30% for testing

# Fit PCA on the training data and transform both train and test sets
pca = PCA(n_components=2)  # Reduce dimensions to 2 principal components for visualization
X_train_pca = pca.fit_transform(X_train)  # Apply PCA on the training data
X_test_pca = pca.transform(X_test)  # Transform test data with the same PCA model

# -MODEL TRAINING-
KNN = KNeighborsClassifier(n_neighbors=15, metric='minkowski')  # Initialize KNN with 15 neighbors and Minkowski distance
KNN.fit(X_train_pca, y_train)  # Train KNN classifier on the PCA-transformed training data

# -MODEL EVALUATION-
y_pred = KNN.predict(X_test_pca)  # Make predictions on the PCA-transformed test data

# Accuracy Calculation
accuracy = accuracy_score(y_test, y_pred)  # Calculate and print the accuracy of the model
print(f"Accuracy: {accuracy * 100:.2f}%")  # Output the accuracy in percentage



X = data_Frame.drop(['Y house price of unit area', 'No'], axis=1).values  # Input variables (features)
y = data_Frame['Y house price of unit area'].values  # Output variable (target)

# Initialize the scaler
scaler = StandardScaler()  # Used for normalizing features (Z-score normalization)
# Normalization via Z-score
#X_normalized = scaler.fit_transform(X)  # Apply normalization to the feature set



# Initialize the model
model = LinearRegression()


# Define a custom RMSE function using NumPy to avoid the deprecation warning
def rmse(y_true, y_pred):
    return np.sqrt(np.mean((y_true - y_pred) ** 2))

# Create a custom scorer using the rmse function
rmse_scorer = make_scorer(rmse, greater_is_better=False)

# Perform 10-fold cross-validation with the custom RMSE scorer
scores = cross_val_score(model, X, y, cv=10, scoring=rmse_scorer)

# Print the RMSE for each fold and the average RMSE
print("RMSE for each fold:", scores)
print("Average RMSE:", np.mean(scores))
