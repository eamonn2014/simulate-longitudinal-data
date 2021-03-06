#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Rshiny ideas from on https://gallery.shinyapps.io/multi_regression/
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#app version 2
require(tidyverse)
require(ggplot2)
library(shiny) 
library(nlme)
library(MASS)
library(rms)
options(max.print=1000000)
fig.width <- 1200
fig.height <- 450
library(shinythemes)        # more funky looking apps
p1 <- function(x) {formatC(x, format="f", digits=1)}
p2 <- function(x) {formatC(x, format="f", digits=2)}
options(width=100)
set.seed(1234)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ui <- fluidPage(theme = shinytheme("journal"),
                
                shinyUI(pageWithSidebar(
                    
                    
                    headerPanel("
                                Simulating, plotting and analysing a cohort followed up over time "),
                    
                    sidebarPanel( 
                        
                        div(p("We simulate, plot and analyse longitudinal data. Two options for the data generation and analysis are provided. 
                              'Log transforming the predictor (time) variable' and 'No transformation to the predictor (time) variable'. 
                              For the former log of time is included in
                              the data generation and accounted for in the model. In the latter, no log transformation is applied nor included in the model. 
                              We also allow both models to be fit including restricted cubic splines with 3 knots from Frank Harrell's rms package.
                              The first tab is a plot of the data including arithmetic means and 95%CI at each timepoint. Tab 2 presents a longitudinal plot of the data
                              again plus inclusion of the modelling approach and allows selection of which interval type to present, the last two tabs present the fitted model and a listing of the data. 
                              
                              The sliders can be used to select the true population parameters. Two plot options are provided on the first tab only, 'All profiles together' and 
                              'Individual profile plots'.")),
                        
                        div(
                            
                             
                            selectInput("Model",
                                        strong("Select modelling preference:"),
                                        choices=c( "Log transforming the predictor (time) variable" , "No transformation to the predictor (time) variable" ,
                                                   "Log transforming with restricted cubic spline" , "No transformation with restricted cubic spline"), width='70%'),
                            
                            
                            actionButton(inputId='ab1', label="R code",   icon = icon("th"), 
                                         onclick ="window.open('https://raw.githubusercontent.com/eamonn2014/simulate-longitudinal-data/master/app.v2/app.R', '_blank')"),   
                            actionButton("resample", "Simulate a new sample"),
                            br(), br(),
                            
                            div(strong("Select true population parameters"),p(" ")),
                            
                            
                            div(("Select the number of subjects, average intercept, average slope, the auto correlation, error SD, intercept SD, 
                            slope SD and the slope intercept correlation as well as the maximum number of visits.
                                 
                                 
                                 Another sample can be taken from the same population/data generating mechanism by clicking 'Simulate a new sample'.")),
                            br(),
                            
                            sliderInput("n",
                                        "No of subjects",
                                        min=2, max=500, step=1, value=200, ticks=FALSE),
                            
                            sliderInput("beta0", "Average intercept", 
                                        min = 50, max = 2000, step=.5, value = c(400), ticks=FALSE) ,
                            
                            sliderInput("beta1", "Average slope",
                                        min = -100, max = 100, step=.5, value = c(-60),ticks=FALSE),
                            
                            sliderInput("ar.val", "True autocorrelation",  
                                        min = -1, max = 1, value = c(.4), step=0.05, ticks=FALSE),
                            
                            sliderInput("sigma", "True error SD", #    
                                        min = 2, max = 200, value = c(100), step=.5, ticks=FALSE),
                            
                            sliderInput("tau0", "True intercept SD", #   
                                        min = 1, max = 100, value = c(25.5), step=.5, ticks=FALSE),
                            
                            sliderInput("tau1", "True slope SD", #    
                                        min = 1, max = 100, value = c(10),step=.5,  ticks=FALSE),
                            
                            sliderInput("tau01", "True intercept slope correlation", #   
                                        min = -1, max = 1, value = c(0), step=0.05, ticks=FALSE),
                            
                            sliderInput("m", "maximum number of visits", #   
                                        min = 2, max = 100, value = c(10), ticks=FALSE, step=1)
                            
                            
                            
                        )
                    ),
                    
                    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~tab panels
                    mainPanel(
                        
                        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        #    tabsetPanel(type = "tabs", 
                        navbarPage(       
                            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
                            tags$style(HTML(" 
                            .navbar-default .navbar-brand {color: cyan;}
                            .navbar-default .navbar-brand:hover {color: blue;}
                            .navbar { background-color: lightgrey;}
                            .navbar-default .navbar-nav > li > a {color:black;}
                            .navbar-default .navbar-nav > .active > a,
                            .navbar-default .navbar-nav > .active > a:focus,
                            .navbar-default .navbar-nav > .active > a:hover {color: pink;background-color: purple;}
                            .navbar-default .navbar-nav > li > a:hover {color: black;background-color:yellow;text-decoration:underline;}
                            .navbar-default .navbar-nav > li > a[data-value='t1'] {color: red;background-color: pink;}
                            .navbar-default .navbar-nav > li > a[data-value='t2'] {color: blue;background-color: lightblue;}
                            .navbar-default .navbar-nav > li > a[data-value='t3'] {color: green;background-color: lightgreen;}
                   ")), 
                            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~end of section to add colour     
                            tabPanel("1 Plot and analysis", 
                                     
                                     selectInput("Plot",
                                                 strong("Select plot preference "),
                                                 choices=c("All profiles together", "Individual profile plots" )),
                                     
                                     div(plotOutput("reg.plot", width=fig.width, height=fig.height)),  
                                     
                                     p(strong("Above a plot of the data and below the output from the statistical analysis.")) ,
                                     
                                     div( verbatimTextOutput("reg.summary"))
                                     
                            ) ,
                            
                            #,
                            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                            tabPanel("2 Confidence and prediction intervals", value=3,
                                   
                                     selectInput('bands', 'Choose the interval to present:',
                                                choices = c('confidence', 'prediction', 'both', 'none')),
                                    #  br(), br(),
                          
                                     
                                     div(plotOutput("reg.plot2", width=fig.width, height=fig.height)),
                                    # tableOutput("view")         
                                     
                                    p(strong("For programming practice four models can be fit to the data; combinations
                                              of log transforming the predictor time and/or including a restricted cubic splines 
                                              transformation of the time predictor with 3 knots using Frank Harrell's rms package. 
                                              We add a small amount of horizontal random noise so the datapoints are more easily distinguished.
                                              In the event a model returns an error, click 'Simulate a new sample' to repeat the experiment.")) 
                                     
                            ) ,
                            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                            tabPanel("3 Model summary", value=3, 
                                     
                                     
                                     div( verbatimTextOutput("test1"))  ,
                                     
                            ) ,
                            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                             tabPanel("4 Data listing", 
                                      
                                      div( verbatimTextOutput("test2"))  , 
                                      
                                      ) #,
                            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                            #  tabPanel("5 tab",  )
                            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        )
                        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    )
                    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~end tab panels
                    
                    #  ) #new
                )
                )
)

server <- shinyServer(function(input, output) {
    
    # --------------------------------------------------------------------------
    # This is where a new sample is instigated only random noise is required to be generated
    random.sample <- reactive({

        # Dummy line to trigger off button-press
        foo <- input$resample

         n <- input$n
         beta0<- input$beta0
         beta1<- input$beta1
         ar.val <- input$ ar.val
         sigma <- input$sigma
         tau0 <- input$tau0
         tau1<- input$tau1
         tau01<- input$tau01
         m <- input$m

       return(list(
            n =n ,
            beta0=beta0,
            beta1=beta1,
            ar.val= ar.val ,
            sigma =sigma,
            tau0 =tau0,
            tau1=tau1,
            tau01=tau01,
            m =m
        ))

    })
    
    # --------------------------------------------------------------------------
    # Set up the dataset based on the inputs 
    # random.sample2 <- reactive({
    #   
    #   sample <- random.sample()
    #   n<- sample$n
    #   beta0<- sample$beta0
    #   beta1<- sample$beta1
    #   ar.val <- sample$ar.val
    #   sigma <- sample$sigma
    #   tau0 <- sample$tau0
    #   tau1<- sample$tau1
    #   tau01<- sample$tau01
    #   m <- sample$m
    #   
    #   return(list( 
    #     n =n ,
    #     beta0=beta0,
    #     beta1=beta1,
    #     ar.val= ar.val ,
    #     sigma =sigma,
    #     tau0 =tau0,
    #     tau1=tau1,
    #     tau01=tau01,
    #     m =m
    #   ))
    #   
    #   
    # })  
    #   
    
    # Return the requesteed dataset
    datasetInput <- reactive({
        switch (input$bands,
                'confidence' = confidence,
                'prediction' = predition,
                'none' = none,
                'both' = both
        )
    })
    
  
    make.regression <- reactive({
        
        #   https://stats.stackexchange.com/questions/28876/difference-between-anova-power-simulation-and-power-calculation
        # 
        # n <- input$n 
        # beta0<- input$beta0
        # beta1<- input$beta1
        # ar.val <- input$ ar.val 
        # sigma <- input$sigma
        # tau0 <- input$tau0
        # tau1<- input$tau1
        # tau01<- input$tau01
        # m <- input$m
        
        # introducing a rand draw , want this to stay constant if different models are seleted.
        sample <- random.sample()
          sample <- random.sample()
          n<- sample$n
          beta0<- sample$beta0
          beta1<- sample$beta1
          ar.val <- sample$ar.val
          sigma <- sample$sigma
          tau0 <- sample$tau0
          tau1<- sample$tau1
          tau01<- sample$tau01
          m <- sample$m
        
        
        
        
        
        p <- round(runif(n,4,m))
        
        ### simulate observation moments (assume everybody has 1st obs)
        obs <- unlist(sapply(p, function(x) c(1, sort(sample(2:m, x-1, replace=FALSE)))))
        
        ### set up data frame
        dat <- data.frame(id=rep(1:n, times=p), obs=obs)
        
        ### simulate (correlated) random effects for intercepts and slopes
        mu  <- c(0,0)
        S   <- matrix(c(1, tau01, tau01, 1), nrow=2)
        tau <- c(tau0, tau1)
        S   <- diag(tau) %*% S %*% diag(tau)
        U   <- mvrnorm(n, mu=mu, Sigma=S)
        
        ### simulate AR(1) errors and then the actual outcomes
        
        dat$eij <- unlist(sapply(p, function(x) arima.sim(model=list(ar=ar.val), n=x) * sqrt(1-ar.val^2) * sigma))
        
        
        return(list(dat1=dat , U=U, p=p)) 
        
    })
    
    
    
    make.regression2 <- reactive({
        
        data <- make.regression()
        
        
        dat <- data$dat1  
        p=data$p
        U=data$U
        beta0<- input$beta0
        beta1<- input$beta1
        
        # sample <- random.sample()
        # U = sample$U
        
        if (input$Model == "Log transforming the predictor (time) variable" | input$Model == "Log transforming with restricted cubic spline")  {
            dat$yij <- (beta0 + rep(U[,1], times=p)) + (beta1 + rep(U[,2], times=p)) *  log(dat$obs) + dat$eij  
        }   else if (input$Model == "No transformation to the predictor (time) variable" | input$Model == "No transformation with restricted cubic spline") {    
            dat$yij <- (beta0 + rep(U[,1], times=p)) + (beta1 + rep(U[,2], times=p)) *  (dat$obs) + dat$eij   
        } 
        
        ### note: use arima.sim(model=list(ar=ar.val), n=x) * sqrt(1-ar.val^2) * sigma
        ### construction, so that the true error SD is equal to sigma
        ### create grouped data object
        dat <- groupedData(yij ~ obs | id, data=dat)   
        
        return(list(dat=dat )) 
        
    })  
    
    
    
    
    
    
    # --------------------------------------------------------------------------
    # Fit the specified regression model
    fit.regression <- reactive({ 
        
        data <- make.regression2()
        
        df <- data$dat
        
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # Conditionally fit the model
        
        if (input$Model == "Log transforming the predictor (time) variable") {
            
            fit.res <-  
                tryCatch( 
                    lme(yij ~ log(obs), random = ~ log(obs) | id, correlation = corAR1(form = ~ 1 | id), data=df)
                    ,  error=function(e) e)
            
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            ###http://stackoverflow.com/questions/8093914
            ###/skip-to-next-value-of-loop-upon-error-in-r-trycatch
            
            if (!inherits(fit.res, "error")) {
                
                #  fit.res <-  summary(fit.res) # for the residuals
                fit.res <-   (fit.res)
            } else  {
                
                fit.res <- NULL
                
            }
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        } else if (input$Model == "No transformation to the predictor (time) variable") {          
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            
            fit.res <-  
                tryCatch( 
                    lme(yij ~  (obs), random = ~  (obs) | id, correlation = corAR1(form = ~ 1 | id), data=df)
                    ,  error=function(e) e)
            
            
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            if (!inherits(fit.res, "error")) {
                
                #fit.res <-  summary(fit.res) # for the residuals
                fit.res <-   (fit.res)
            } else  {
                
                fit.res <- NULL
                
            }
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            
        }  else if (input$Model == "Log transforming with restricted cubic spline") {          
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            
            fit.res <-  
                tryCatch( 
                    lme(yij ~  rcs(log(obs),3), random = ~  log(obs) | id, correlation = corAR1(form = ~ 1 | id), data=df)
                    ,  error=function(e) e)
            
            
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            if (!inherits(fit.res, "error")) {
                
                #fit.res <-  summary(fit.res) # for the residuals
                fit.res <-   (fit.res)
            } else  {
                
                fit.res <- NULL
                
            }
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   
        } 
        else if (input$Model ==  "No transformation with restricted cubic spline") {          
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            
            fit.res <-  
                tryCatch( 
                    lme(yij ~  rcs(obs,3), random = ~  (obs) | id, correlation = corAR1(form = ~ 1 | id), data=df)
                    ,  error=function(e) e)
            
            
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            if (!inherits(fit.res, "error")) {
                
                # fit.res <-  summary(fit.res) # for the residuals
                fit.res <-   (fit.res)
            } else  {
                
                fit.res <- NULL
                
            }
        }   
        
        
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        # Get the model summary
        if (is.null(fit.res)) {
            
            fit.summary <- NULL
            
        } else {
            
            fit.summary <-  (fit.res)
        }
        
        return(list(  
            
            fit.summary=fit.summary 
            
        ))
        
    })     
    
    # --------------------------------------------------------------------------
    #---------------------------------------------------------------------------
    # Plot a scatter of the data  
    
    output$reg.plot <- renderPlot({         
        
        # Get the current regression data
        data1 <- make.regression2()
        
        df <- data1$dat
        
        # Conditionally plot
        if (input$Plot == "All profiles together") {
            
            #base plot~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            #https://rstudio-pubs-static.s3.amazonaws.com/308410_2ece93ee71a847af9cd12fa750ed8e51.html
            names(df) <- c("ID","VISIT","eij","value")
            
            df_summary <- df %>% # the names of the new data frame and the data frame to be summarised
                group_by(VISIT) %>%                # the grouping variable
                summarise(mean_PL = mean(value, na.rm=TRUE),  # calculates the mean of each group
                          sd_PL = sd(value, na.rm=TRUE),      # calculates the sd of each group
                          n_PL = length(na.omit(value)),      # calculates the sample size per group
                          SE_PL = sd(value, na.rm=TRUE)/sqrt(length(na.omit(value)))) # SE of each group
            
            df_summary1 <- merge(df, df_summary)  # merge stats to dataset
            
            df_summary1$L2SE <- df_summary1$mean_PL - 2*df_summary1$SE_PL
            df_summary1$H2SE <- df_summary1$mean_PL + 2*df_summary1$SE_PL
            
            
            pr1 <- ggplot((df_summary1), aes(x = VISIT, y =value, color = ID)) +
                geom_line( size=.5, alpha=0.2) +
                stat_summary(geom="line",  fun.y=mean, colour="black", lwd=0.5) +  # , linetype="dashed"
                stat_summary(geom="point", fun.y=mean, colour="black") +
                geom_errorbar(data=(df_summary1), 
                              aes( ymin=L2SE, ymax=H2SE ), color = "black",
                              width=0.05, lwd = 0.05) +
                scale_y_continuous(expand = c(.1,0) ) +
                
                
                
                scale_x_continuous(breaks = c(unique(df$VISIT)),
                                   labels = 
                                       c(unique(df$VISIT))
                ) +
                
                EnvStats::stat_n_text(size = 4, y.pos = max(df_summary1$value, na.rm=T)*1.1 , y.expand.factor=0, 
                                      angle = 0, hjust = .5, family = "mono", fontface = "plain") + #295 bold
                
                theme(panel.background=element_blank(),
                      # axis.text.y=element_blank(),
                      # axis.ticks.y=element_blank(),
                      # https://stackoverflow.com/questions/46482846/ggplot2-x-axis-extreme-right-tick-label-clipped-after-insetting-legend
                      # stop axis being clipped
                      plot.title=element_text(), plot.margin = unit(c(5.5,12,5.5,5.5), "pt"),
                      legend.text=element_text(size=12),
                      legend.title=element_text(size=14),
                      legend.position="none",
                      axis.text.x  = element_text(size=10),
                      axis.text.y  = element_text(size=10),
                      axis.line.x = element_line(color="black"),
                      axis.line.y = element_line(color="black"),
                      plot.caption=element_text(hjust = 0, size = 7))
            
            
            print(pr1 + labs(y="Response", x = "Visit") + 
                      ggtitle(paste0("Individual responses ",
                                     length(unique(df$ID))," patients & arithmetic mean with 95% CI shown in black\nNumber of patient values at each time point") )
                  
            )
            
        } else {
            
            plot(df, pch=19, cex=.5)
            
        }
        
    })
    
    
    output$view <- renderTable({
        obs= data.frame(obs=make.regression2()$obs)
        return(obs=obs)
    })
    
    
    
    #---------------------------------------------------------------------------
    output$reg.plot2 <- renderPlot({         
        
        # Get the current regression data
        data1 <- make.regression2()
        
        d <- data1$dat
        
        
        foo <- d
        
        obs= data.frame(obs=d$obs)  # took a while to solve this was required!
        
        new.dat <- (obs)
        
        model.mx  <- fit.regression()$fit.summary
        
        #new.data <- NA
        ##################################################
        # #create data.frame with new values for predictors
        # #more than one predictor is possible
        #new.dat <- data.frame(d$obs)
        # #predict response
        new.dat$pred <- predict(model.mx, newdata=new.dat,level=0)
        # 
        # #create design matrix
        Designmat <- model.matrix(eval(eval(model.mx$call$fixed)[-2]),new.dat[-ncol(new.dat)])
        # 
        # #compute standard error for predictions
        predvar <- diag(Designmat %*% model.mx$varFix %*% t(Designmat))
        new.dat$SE <- sqrt(predvar)
        new.dat$SE2 <- sqrt(predvar+model.mx$sigma^2)
        # 
        
        n<-dim(foo)[1]
        foo$obs<-foo$obs+rnorm(n, mean=0, sd=.1) #add jitter
        
        
        df_summary <- d %>% # the names of the new data frame and the data frame to be summarised
            group_by(obs) %>%                # the grouping variable
            summarise(mean_PL = mean(yij, na.rm=TRUE),  # calculates the mean of each group
                      sd_PL = sd(yij, na.rm=TRUE),      # calculates the sd of each group
                      n_PL = length(na.omit(yij)),      # calculates the sample size per group
                      SE_PL = sd(yij, na.rm=TRUE)/sqrt(length(na.omit(yij)))) # SE of each group
        
        df_summary1 <- merge(d, df_summary)  # merge stats to dataset
        
        df_summary1$L2SE <- df_summary1$mean_PL - 2*df_summary1$SE_PL
        df_summary1$H2SE <- df_summary1$mean_PL + 2*df_summary1$SE_PL
        
        
        # 
        p1 <- px <- NULL 
        
        
        if (input$bands == 'none') {
            
        p1 <- 
            ggplot(new.dat,aes(x=obs,y=pred)) +
            geom_line(colour="black") +
            guides(colour=FALSE) 
            
        
        } else if (input$bands == 'both') {
            
            p1 <- 
                ggplot(new.dat,aes(x=obs,y=pred)) +
                geom_line(colour="black") +
                guides(colour=FALSE) +
                geom_ribbon(aes(ymin=pred-2*SE,ymax=pred+2*SE),  alpha=0.2,fill="purple") +
                geom_ribbon(aes(ymin=pred-2*SE2,ymax=pred+2*SE2),  alpha=0.2,fill="grey") 
           
    }  else if (input$bands == 'confidence') {
    
    p1 <- 
        ggplot(new.dat,aes(x=obs,y=pred)) +
        geom_line(colour="black") +
        guides(colour=FALSE) +
        geom_ribbon(aes(ymin=pred-2*SE,ymax=pred+2*SE),  alpha=0.2,fill="purple") 
         
    } else if (input$bands == 'prediction') {
        
        p1 <- 
            ggplot(new.dat,aes(x=obs,y=pred)) +
            geom_line(colour="black") +
            guides(colour=FALSE) +
            geom_ribbon(aes(ymin=pred-2*SE2,ymax=pred+2*SE2),  alpha=0.2,fill="grey") 
        
    }
        
            
       p2 <- p1 +     geom_point(data=foo,aes(x=obs,y=yij),size=0.6) +
           # scale_y_continuous(limits = c(min(foo$yij)-3, max(foo$yij)+3)) +
          scale_x_continuous(limits = c(min(obs)-.5,max(obs)+.5) , breaks=seq(min(obs)-.5 :max(obs)+.5)  ,
                              labels= seq(min(obs) -.5:max(obs)+.5) ) +
            geom_line(data=foo,aes(x=obs,y=yij , group=id, colour=factor(id) ), linetype = "dotted",   size=0.6)  +
            scale_colour_discrete(name = "Samples") +
            xlab("Visit") +
            ylab("Response") +
           scale_y_continuous(expand = c(.1,0) ) +
           
           
           
           # scale_x_continuous(breaks = c(unique(foo$obs)),
           #                    labels = 
           #                        c(unique(foo$obs))
           # ) +
           
           EnvStats::stat_n_text(size = 4, y.pos = max(df_summary1$yij, na.rm=T)*1.1 , y.expand.factor=0, 
                                 angle = 0, hjust = .5, family = "mono", fontface = "plain") 
        
        
        
        px <- p2 + ggtitle(paste(length(unique(foo$id)), "subjects", sep=" " )) +
            theme(panel.background=element_blank(),
                  # axis.text.y=element_blank(),
                  # axis.ticks.y=element_blank(),
                  # https://stackoverflow.com/questions/46482846/ggplot2-x-axis-extreme-right-tick-label-clipped-after-insetting-legend
                  # stop axis being clipped
                  plot.title=element_text(), plot.margin = unit(c(5.5,12,5.5,5.5), "pt"),
                  legend.text=element_text(size=12),
                  legend.title=element_text(size=14),
                  legend.position="none",
                  axis.text.x  = element_text(size=10),
                  axis.text.y  = element_text(size=10),
                  axis.line.x = element_line(color="black"),
                  axis.line.y = element_line(color="black"),
                  plot.caption=element_text(hjust = 0, size = 7))
        
        print(px + labs(y="Response", x = "Visit") +  
                  ggtitle(paste0("Individual responses ",
                                 length(unique(d$id))," patients with choice of 95% intervals\nThe number of patient values at each time point is presented") ) )
        
        
        ########################################################
        
        #base plot~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        #https://rstudio-pubs-static.s3.amazonaws.com/308410_2ece93ee71a847af9cd12fa750ed8e51.html
        # names(df) <- c("ID","VISIT","eij","value")
        # 
        # df_summary <- df %>% # the names of the new data frame and the data frame to be summarised
        #   group_by(VISIT) %>%                # the grouping variable
        #   summarise(mean_PL = mean(value, na.rm=TRUE),  # calculates the mean of each group
        #             sd_PL = sd(value, na.rm=TRUE),      # calculates the sd of each group
        #             n_PL = length(na.omit(value)),      # calculates the sample size per group
        #             SE_PL = sd(value, na.rm=TRUE)/sqrt(length(na.omit(value)))) # SE of each group
        # 
        # df_summary1 <- merge(df, df_summary)  # merge stats to dataset
        # 
        # df_summary1$L2SE <- df_summary1$mean_PL - 2*df_summary1$SE_PL
        # df_summary1$H2SE <- df_summary1$mean_PL + 2*df_summary1$SE_PL
        # 
        # 
        # pr1 <- ggplot((df_summary1), aes(x = VISIT, y =value, color = ID)) +
        #   geom_line( size=.5, alpha=0.2) +
        #   stat_summary(geom="line",  fun.y=mean, colour="black", lwd=0.5) +  # , linetype="dashed"
        #   stat_summary(geom="point", fun.y=mean, colour="black") +
        #   geom_errorbar(data=(df_summary1), 
        #                 aes( ymin=L2SE, ymax=H2SE ), color = "black",
        #                 width=0.05, lwd = 0.05) +
        #   scale_y_continuous(expand = c(.1,0) ) +
        #   
        #   
        #   
        #   scale_x_continuous(breaks = c(unique(df$VISIT)),
        #                      labels = 
        #                        c(unique(df$VISIT))
        #   ) +
        #   
        #   EnvStats::stat_n_text(size = 4, y.pos = max(df_summary1$value, na.rm=T)*1.1 , y.expand.factor=0, 
        #                         angle = 0, hjust = .5, family = "mono", fontface = "plain") + #295 bold
        #   
        #   theme(panel.background=element_blank(),
        #         # axis.text.y=element_blank(),
        #         # axis.ticks.y=element_blank(),
        #         # https://stackoverflow.com/questions/46482846/ggplot2-x-axis-extreme-right-tick-label-clipped-after-insetting-legend
        #         # stop axis being clipped
        #         plot.title=element_text(), plot.margin = unit(c(5.5,12,5.5,5.5), "pt"),
        #         legend.text=element_text(size=12),
        #         legend.title=element_text(size=14),
        #         legend.position="none",
        #         axis.text.x  = element_text(size=10),
        #         axis.text.y  = element_text(size=10),
        #         axis.line.x = element_line(color="black"),
        #         axis.line.y = element_line(color="black"),
        #         plot.caption=element_text(hjust = 0, size = 7))
        # 
        # 
        # print(pr1 + labs(y="Response", x = "Visit") + 
        #         ggtitle(paste0("Individual responses ",
        #                        length(unique(df$ID))," patients & arithmetic mean with 95% CI shown in black\nNumber of patient values at each time point") )
        #       
        # )
        # 
        
        
    })
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~      
    
    output$test1 <- renderPrint({ 
        
        model.mx  <- fit.regression()$fit.summary
        
        model.mx <- summary(model.mx)
        
        return(model.mx )
        
    })
    
    output$test2 <- renderPrint({ 
        
        d  <- make.regression2()$d
        
        return(d )
        
    })
    
    # between <- reactive({         
    #   
    #   model.mx<- test1()$model.mx
    #   
    #          d <- test2()$d
    # 
    #          return(list(  
    #            
    #            d=d, model.mx=model.mx 
    #            
    #          ))
    # 
    #   
    # })
    #   
    #   
    # output$reg.plot2 <- renderPlot({         
    #   
    #   
    #   model.mx <- test1()$model.ma 
    # 
    #   plot(1:10)
    #   
    #  })
    
    
    
    #--------------------------------------------------------------------------
    #---------------------------------------------------------------------------
    # Plot residuals 
    
    #  output$residual <- renderPlot({         
    
    # Get the current regression model
    # d  <- fit.regression()
    # 
    # f<- d$ff
    # 
    # par(mfrow=c(3,2))
    # plot(f)
    # 
    # #dd <- d$fit.res
    # anova.residuals <- residuals( object =  f) # extract the residuals
    # # A simple histogram
    # hist( x = anova.residuals , breaks=50, main=paste("Histogram of ANOVA residuals, SD=",p2(sd(anova.residuals)),"")) # another way of seeing residuals
    # par(mfrow=c(1,1)) 
    
    #   })
    
    #---------------------------------------------------------------------------
    # Show the summary for the 
    output$reg.summary <- renderPrint({
        
        summary <- fit.regression()$fit.summary
        
        if (!is.null(summary)) {
            
            return(fit.regression()$fit.summary)
            
        } else if (is.null(summary)){
            
            return("error")
        }
        
    })
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # the data to print
    output$summary2 <- renderPrint({ 
        
        return(make.regression2()$dat)
        
    })
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # the data to print, I wooulf like to reuse this but dont think it is possible? So I add another function to collect the same information below
    # output$byhand <- renderPrint({
    #     
    #     return(explain()$ANOVA)
    #     
    # })
    # #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # output$byhand2 <- renderPrint({
    #     
    #     return(explain()$ANOVA2)
    #     
    # })
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
})

# Run the application 
shinyApp(ui = ui, server = server)