#ML1 Assignment 1
#Marina Nikon

#BACKGROUND:
#The data is a marketing campaign data of a skin care clinic associated with its success.

#Description of variables
#Success: Response to marketing campaign of Skin Care Clinic which offers both 
#products and services. (1: email Opened, 0: email not opened)
#AGE: Age Group of Customer
#Recency_Service: Number of days since last service purchase
#Recency_Product: Number of days since last product purchase
#Bill_Service: Total bill amount for service in last 3 months
#Bill_Product: Total bill amount for products in last 3 months
#Gender (1: Male, 2: Female)


#QUESTIONS
#------------------------------
# - Import Email Campaign data.                                                       
#------------------------------
  
    ##Note: Answer following questions using entire data and do not create test data.

# Load the data
campaign<-read.csv("Email_Campaign.csv", header = TRUE) # Import data
head(campaign) # View first 6 rows
dim(campaign) # Check the dimension of the dataset
summary(campaign) #Summarizing data and checking for missing values
str(campaign) # Check the structure of the dataset
anyNA(campaign) # Check for missing values
#campaign <- na.omit(birds)

#Observations:
#There are no missing values

library(dplyr)
#Convert categorical variables to factors
campaign1 <- campaign %>%
  mutate_at(vars(c('Gender','AGE','Success')), ~as.factor(.))


#Setting the threshold
success_counts<-data.frame(table(campaign1$Success))
colnames(success_counts)[1] <- "Success"
success_counts$Percent <- success_counts$Freq / sum(success_counts$Freq)
#Count the occurrences of each value in the "Success" column
success_counts
#Observations:
#Response Freq   Percent
#1      0  503 0.7364568
#2      1  180 0.2635432

#Set threshold to match the proportion of positive cases. 
#This value will be used as threshold for PredY
threshold <- 0.26


#------------------------------
# Logistic Regression Model
#------------------------------

#------------------------------
# Perform Binary Logistic Regression to model “Success”. 
#------------------------------
set.seed(123) #to use the same data

#Building Model
glm_model<-glm(Success ~ Gender + AGE + Recency_Service + Recency_Product + Bill_Service + 
             Bill_Product, data = campaign1, family=binomial)

summary(glm_model)
#Observations:
#Coefficients:
#                 Estimate Std. Error z value Pr(>|z|)    
#(Intercept)     -1.02152    0.27946  -3.655 0.000257 ***
#Gender2         -0.23697    0.21414  -1.107 0.268462    
#AGE<=45          0.15725    0.26726   0.588 0.556293    
#AGE<=55          0.67267    0.36588   1.839 0.065986 .  
#Recency_Service -0.24592    0.02944  -8.352  < 2e-16 ***
#Recency_Product -0.09087    0.02207  -4.117 3.84e-05 ***
#Bill_Service     0.09293    0.01854   5.013 5.36e-07 ***
#Bill_Product     0.51966    0.08103   6.413 1.43e-10 ***
#  ---
#Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

#(Dispersion parameter for binomial family taken to be 1)

#Null deviance: 787.81  on 682  degrees of freedom
#Residual deviance: 545.98  on 675  degrees of freedom
#AIC: 561.98

#Number of Fisher Scoring iterations: 6

#Since p-value is <0.05 for Recency_Service, Recency_Product, Bill_Service,
#Bill_Product these independent variables are statistically significant.
#AGE<=55 is on a border line, it was not retained
#AIC: 561.98


#Remove insignificant variables and refit model 
glm_model_1<-glm(Success ~ Recency_Service + Recency_Product + Bill_Service + 
                 Bill_Product, data = campaign1, family=binomial)

summary(glm_model_1)
#Observation:
#Coefficients:
#                Estimate Std. Error z value Pr(>|z|)    
#(Intercept)     -1.15780    0.24777  -4.673 2.97e-06 *** 
#Recency_Service -0.22984    0.02728  -8.426  < 2e-16 ***
#Recency_Product -0.07389    0.01932  -3.825 0.000131 ***
#Bill_Service     0.09183    0.01846   4.974 6.55e-07 ***
#Bill_Product     0.51852    0.08083   6.415 1.41e-10 ***

#Since p-value is <0.05 for all variables, all these independent variables are 
#significant and signs of the coefficients are also logical.
#AIC: 560.87


#------------------------------
#  Interpret sign of each significant variable in the model.
#------------------------------

#All four predictors are highly significant as p<0.001 and the sign
#of each coefficient is logically aligned with expectations.

#Recency_Service (-0.22984) - The negative sign indicates that the longer
#the customers did not use the service, the less likely they will open the
# campaign email. In contrast, customers who used a service more recently
#are more likely to respond.

#Recency_Product (-0.07389) - It is similar to service recency. Customers
#who recently purchased the product will more likely respond to the 
#campaign. The mor time has passed since the last purchase, the lower is 
#the probability of success.

#Bill_Service (0.09183) - Positive sign suggests that customers who spent more 
#money on service in the last 3 months are more likely to open the campaign
#email, indicating a stronger interest or loyalty.

#Bill_Product (0.51852) - Positive sign suggests that the higher is spending on 
#products the higher is the probability customers will respond to the 
#campaign. These customers are highly engaged and responsive.

#In general the model indicates that recent and high-spending customers are
#more likely to engage with the campaign.


#Checking Multicollinearity
library(car)
vif(glm_model_1)
#Observations:
#Recency_Service Recency_Product    Bill_Service    Bill_Product 
#       1.737141        1.131628        1.320786        2.218089 
#None of the GVIF values are greater than 5, meaning there is no Multicollinearity.


#------------------------------
#Compare performance of Binary Logistic Regression (significant variables) 
#and Naïve Bayes Method (all variables) using area under the ROC curve. 
#------------------------------

#Obtain ROC curve and AUC for Binary Logistic Regression
library(ROCR)
campaign1$predprob<-round(fitted(glm_model_1),2)
predtrain<-prediction(campaign1$predprob,campaign1$Success)
perftrain<-performance(predtrain,"tpr","fpr")
plot(perftrain, col="orchid", main="ROC Curve (Logistic Regression)")
abline(0,1, col="blue")


#Checking area under the ROC curve / AUC
auc_glm<-performance(predtrain,"auc")
auc_glm@y.values
#Observations:
# 0.8524961 - very good auc value


#Predicted Y for for Binary Logistic Regression
campaign1$predY<-as.factor(ifelse(campaign1$predprob>threshold,1,0))

#Confusion matrix for  Binary Logistic Regression 
library(caret)
confusionMatrix(campaign1$predY,campaign1$Success,positive="1")
#Observation:
#          Reference
#Prediction   0   1
#         0 379  38
#         1 124 142
# Accuracy : 0.7628 - means the model correctly predicts 76% of the time (good)
# Sensitivity : 0.7889 - the model correctly identifies 79% of responses (good)        
# Specificity : 0.7535 - the model correctly identifies 75% of responses (good)       

#The overall model accuracy is 76%. The area under ROC curve is 85.25


#------------------------------
# Naïve Bayes Model
#------------------------------

#install.packages("e1071")
library(e1071)
set.seed(123) #to use the same data


#Building Model
nb_model<-naiveBayes(Success ~ Gender + AGE + Recency_Service + Recency_Product + Bill_Service + 
                 Bill_Product, data = campaign1)

summary(nb_model)


# Obtain ROC curve and AUC for campaign1 data

predprob_nb <- predict(nb_model, campaign1, type = "raw")

# Computing AUC value for ROC curve
nb_pred<-prediction(predprob_nb[,2],campaign1$Success)
nb_perf<-performance(nb_pred,"tpr","fpr")
plot(nb_perf, col="orchid", main="ROC Curve, NB Model")
abline(0,1, col="blue")


#Checking area under the ROC curve
auc_nb<-performance(nb_pred,"auc")
auc_nb@y.values
#Observations:
# 0.811818


# Obtain Confusion Matrix for Naïve Bayes 

#Predicted Y for campaign1 data
campaign1$nb_predY<-as.factor(ifelse(predprob_nb[,2]>threshold,1,0))

#Confusion matrix for train data    
confusionMatrix(campaign1$nb_predY,campaign1$Success,positive="1")
#Observations:
#          Reference
#Prediction   0   1
#         0 422  65
#         1  81 115
#Accuracy : 0.7862 - means the model correctly predicts 79% of the time (good)          
#Sensitivity : 0.6389 - the model correctly identifies 64% of responses (low)                   
#Specificity : 0.8390 - the model correctly identifies 84% of of responses (very good)          

#The overall model accuracy is 79%. The area under ROC curve is 81.18


#------------------------------
# Support Vector Machines Model
#------------------------------

#------------------------------
#Implement binary logistic regression and Support Vector Machines by 
#combining service and product variables. 
#------------------------------

#Building Model
set.seed(123) #to use the same data
model_svm<-svm(Success ~ Gender + AGE + Recency_Service + Recency_Product + Bill_Service + 
                 Bill_Product, data = campaign1, type="C", probability=TRUE, kernel="linear")
model_svm


#Predicting probabilities 
pred1<-predict(model_svm,campaign1,probability=TRUE)
pred2<-attr(pred1,"probabilities")[,"1"]

# Computing AUC value for ROC curve
sv_pred<-prediction(pred2,campaign1$Success)
sv_perf<-performance(sv_pred,"tpr","fpr")
plot(perf)
abline(0,1)
plot(sv_perf, col="orchid", main="ROC Curve, SVM Model")
abline(0,1, col="blue")


#Checking area under the ROC curve
auc_sv<-performance(sv_pred,"auc")
auc_sv@y.values
#Observations:
#0.8539209


#Confusion Matrix 
campaign1$predY<-as.factor(ifelse(pred2>threshold,1,0))
confusionMatrix(campaign1$predY,campaign1$Success,positive="1")
#Observations:
#          Reference
#Prediction   0   1
#         0 372  39
#         1 131 141
                                          
#Accuracy : 0.7511 - means the model correctly predicts 75% of the time (good) 
#Sensitivity : 0.7833 - the model correctly identifies 78% of responses (good)          
#Specificity : 0.7396 - the model correctly identifies 74% of responses (good)

#Observations:
#The overall model accuracy is 75%. The area under ROC curve is 85.39


#------------------------------
#Comparison of the data
#------------------------------

# Create data frame of model performance
model_comparison <- data.frame(
  Model = c("Binary Logistic Regression", "Naive Bayes", "Support Vector Machines"),
  AUC = c(0.8525, 0.8118, 0.8539),
  Accuracy = c(0.7628, 0.7862, 0.7511),
  Sensitivity = c(0.7889, 0.6389, 0.7833),
  Specificity = c(0.7535, 0.8390, 0.7396)
)

# View table
print(model_comparison)

#Visualize with a Grouped Bar Chart

# Load ggplot2 for visualization
library(ggplot2)
library(tidyr)

# Reshape data to long format
model_comparison_long <- pivot_longer(model_comparison, 
                                      cols = -Model, 
                                      names_to = "Metric", 
                                      values_to = "Score")

# Plot grouped bar chart
ggplot(model_comparison_long, aes(x = Model, y = Score, fill = Metric)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7, color = "black") +
  labs(title = "Model Performance Comparison on Test Data",
       x = "Model", y = "Score") +
  scale_fill_brewer(palette = "Set2") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 15, hjust = 1))


#Conclusion:
#SVM modelhas the highest AUC(0.8539), followed very closely by LR Model(0.8525)
#NB method has highest accuracy (0.7862) and slightly lower AUC 0.8118), but has
#lowest sensitivity (0.6389), meaning it misses more positive responses, but
#correctly identifies non-responders.










