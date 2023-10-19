# Load the libraries
library(arules)
library(arulesViz)
library(datasets)
data(Groceries)
# Load the data set : Items set structure - List Type; Cannot see properly
Groceries
#str(Groceries)
head(Groceries)
inspect(Groceries[1:5])
# Load and preprocess the grocery dataset
transactions <- as(Groceries, "transactions")
# View the first few transactions
# Convert transactions to matrix representation
trans_matrix <- as(transactions, "matrix")

# Perform clustering
distances <- proxy::dist(trans_matrix)
clusters <- kmeans(distances, centers = 5)  # Assuming 3 clusters
barplot(table(clusters$cluster), main = "Cluster Visualization")
# Print clustered transaction data
for (i in 1:max(clusters$cluster)) {
  cat("Cluster", i, "\n")
  cluster_center <- colMeans(trans_matrix[clusters$cluster == i, ])
  print(cluster_center)
  cat("\n")
}
# Print cluster information
cat("Cluster Information:", "\n")
cat("Cluster Sizes:", "\n")
print(table(clusters$cluster))
# Create an item frequency plot for the top 20 items
itemFrequencyPlot(Groceries,topN=20,type="absolute")
#set the min support to 0.001 , minimum conf of 0.8 ; show top 5 rules
# Get the rules
for (i in 1:5) {
  cluster_transactions <- transactions[clusters$cluster == i]
  
  # Generate association rules for the current cluster
  cluster_rules <- apriori(cluster_transactions, parameter = list(support = 0.05, confidence = 0.3))
  
  # Print the association rules for the current cluster
  cat("Cluster", i, "Association Rules:", "\n")
  for (j in 1:5){
    cat("Rule", j, ":", "\n")
    inspect(cluster_rules[j])
  }
  cat("\n")
  
  # Interactive Graph - Seperate Window
  inspect(cluster_rules[1:5])
  plot(cluster_rules[1:5],method="graph",engine='interactive')
}

rules <- apriori(Groceries, parameter = list(supp = 0.001, conf = 0.8))

# Show the top 5 rules, but only 2 digits
options(digits=5)
inspect(rules[1:5])
#[3] if someone buys yogurt & cereals, they are 81% likely to buy whole milk too.
summary(rules)
# 410 rules, Most rules are 4 items long
# Sort Rules The first issue we see here is that the rules are not sorted. Often we will want the most relevant rules first. Lets say we wanted to have the most likely rules. We can easily sort by confidence by executing the following code.

rules<-sort(rules, by="lift", decreasing=TRUE)
inspect(head(rules))
#Rule 4/ other is perhaps excessively long. Lets say you wanted more concise rules. That is also easy to do by adding a “maxlen” parameter to your apriori function:
rules <- apriori(Groceries, parameter = list(supp = 0.001, conf = 0.8,maxlen=3))
inspect(head(rules))

# Redundancies ####
subset.matrix <- is.subset(rules, rules)
subset.matrix[lower.tri(subset.matrix, diag=T)] <- NA
redundant <- colSums(subset.matrix, na.rm=T) >= 1
rules.pruned <- rules[!redundant]
rules<-rules.pruned
inspect(rules)
# Target Items
#Now that we know how to generate rules, limit the output, lets say we wanted to target items to generate rules. There are two types of targets we might be interested in that are illustrated with an example of “whole milk”:
#  What are customers likely to buy before buying whole milk
#What are customers likely to buy if they purchase whole milk?
#This essentially means we want to set either the Left Hand Side and Right Hand Side. This is not difficult to do with R!
# 1st part
rules<-apriori(data=Groceries, parameter=list(supp=0.001,conf = 0.08), 
               appearance = list(default="lhs",rhs="whole milk"),
               control = list(verbose=F))
rules<-sort(rules, decreasing=TRUE,by="confidence")
inspect(rules[1:5])
#Likewise, we can set the left hand side to be “whole milk” and find its antecedents.
#Note the following:
#  We set the confidence to 0.15 since we get no rules with 0.8
#We set a minimum length of 2 to avoid empty left hand side items
rules<-apriori(data=Groceries, parameter=list(supp=0.001,conf = 0.15,minlen=2), appearance = list(default="rhs",lhs="whole milk"),
               control = list(verbose=F))
rules<-sort(rules, decreasing=TRUE,by="confidence")
inspect(rules)

# Visualisation ####
#The last step is visualization. Lets say you wanted to map out the rules in a graph. We can do that with another library called “arulesViz”.
library(arulesViz)
# Interactive Graph - Seperate Window
inspect(rules[1:5])
plot(rules[1:5],method="graph",engine='interactive')

