---
layout: project-detail
title: Java Ecosystem Simulator
subtitle: An ecosystem simulator for exploring individual and group behavior.
date: 2018-07-24
cover: "/assets/img/projects/ecosystem/cover.png"
external-link: "https://github.com/boningdong/JavaEcoSimulator"
tags:
    - software
    - java
---
Model a population by giving every animal its own rules.

This Java simulator explores how individual behavior can produce group-level predator–prey patterns. Tian Gao inspired the project, which I built to practice Java, object-oriented design patterns, and multithreading.

::: featured-link
[View source on GitHub](https://github.com/boningdong/JavaEcoSimulator)
:::

# Simulation Model

The simulator aims to create a balanced sheep-and-wolf ecosystem. Statistical models show that wolf and sheep population curves should have a nearly 180-degree phase difference, reflecting a derivative relationship. These curves usually describe group effects based on statistical results. This project explores how individual behavior affects group behavior by programming the behavior of each sheep and wolf entity.

## The simulator has the following features
- Each animal is an individual. It determines its own behavior based on its surrounding area and status.
- Both wolves and sheep get hungry. If their food value reaches zero, they die.
- Both wolves and sheep grow old; when they reach their maximum age, they die.
- Both wolves and sheep have a desire value; if their desire is strong, they find a mating target.
- Mating may make wolves or sheep pregnant, and wolf or sheep babies may appear on the map.
- Mating reduces food value.
- Newborn animals inherit their parents' properties, including speed and sight range, with variation caused by mutation.
- When a wolf is hungry, it finds a sheep target and hunts it.
- While chasing a mating target or hunting target, animals run faster, but faster speed leads to a quicker food drop.
- The food gain rate for sheep is based on how many sheep are nearby. If there are too many sheep, the area cannot support all of them.
- A Statistician class records the game data.
- A Plotter plots changes in the number of entities over time.
- All parameters and features are adjusted and designed to help keep the ecosystem balanced.
# Results
The simulator functions correctly, and a sheep-and-wolf relationship can be seen in the results.

![Sheep and wolf simulation](/assets/img/projects/ecosystem/ecosystem_1.gif "Sheep and wolf simulation")

![Population trend over time](/assets/img/projects/ecosystem/ecosystem_2.gif "Population trend over time")
