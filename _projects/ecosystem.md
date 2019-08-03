---
layout: project-post
title: Java Based Ecosystem Simulator
update-date: 2018-07-24
external-link: "https://github.com/boningdong/JavaEcoSimulator"
tags:
    - software
    - java
---

# Description
This project is a Java-based ecosystem simulator aiming for creating a balanced sheep-wolves ecosystem. From the statistic class, we know that the curves of the wolves-sheep system should have a nearly 180-degree phase difference - a derivative-relationship. Usually, those curves we see are based on statistic result, in other word, a group effect. The purpose of this project is to explore how individual behavior in a group will affect group behavior. Specifically, in this project, I was trying to produce the same sheep-wolves curves by programming the behavior of each sheep or wolf entity.

It's also worth to mention that my friend Tian Gao inspired this project. I build this for fun and for getting familiar with Java programming language, design pattern, and practice with several techniques like multithreading.

## The simulator has the following features
- Each animal is an individual. It determines it's own behavior based on its surrounding area and its own status.
- Both of the wolves and sheep will get hungry. If their food value reaches zero, they will die.
- Both of the wolves and sheep will getting old; when they reach their maximum age, they will die.
- Both of the wolves and sheep have desire value; if their desire is strong, they will find a mating target.
- Mate behavior may cause the wolves or sheep pregnant, and wolves or sheep babies may generate on the map.
- Mate behavior will lose food value.
- The newborn baby will inherit its parents' properties (speed and sight range), and it will vary because of the mutation.
- When a wolf is hungry, it will find a sheep target and hunt the target.
- During chasing a mating target and a hunting target, animals will run faster, but faster speed leads to a quicker food drop.
- The food gain rate for sheep is based on how many sheep nearby. If there are too many sheep, the area cannot support all the sheep to survive.
- A Statistician class is used for recording the data of the game.
- A Plotter will plot the change of entities' number with time went by.
- All the parameters and features are adjusted and designed to make sure the ecosystem can be balanced.

# Results
The simulator functions correctly, and a sheep-wolves relationship can be seen from the diagram result.