args <- commandArgs(trailingOnly = TRUE)

print(as.numeric(args));

x <- 0
while(x < as.numeric(args)) {
    x <- x+1;
    # print(x);
}


