# 🍜  Case study 1: Danny's Diner

## Table of Contents
- [Introduction](#Introduction)
- [Problem Statement](#Problem-Statement)
- [Entity Relationship Diagram](#Entity-Relationship-Diagram)
- [Case Study Questions](#Case-Study-Questions)
- [Solutions](#Solutions)

***

## Introduction
Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

## Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

## Entity Relationship Diagram

![image](https://i.imgur.com/7swrArS.png)

**Table 1: sales**     

  The sales table captures all customer_id level purchases with an corresponding order_date and product_id information for when and what menu items were ordered.

**Table 2: menu**

  The menu table maps the product_id to the actual product_name and price of each menu item.

**Table 3: members**

  The final members table captures the join_date when a customer_id joined the beta version of the Danny’s Diner loyalty program.

## Case Study Questions

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
10. What is the total items and amount spent for each member before they became a member?
11. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
12. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

## Solutions

View my solutions [here](https://github.com/Chicong00/8-week-SQL-challenge/blob/3ec08195aeba23b4b943a5f6eda1afec5ac00e31/Case%20Study%20%231%20-%20Danny's%20Diner/SOLUTION.md)
