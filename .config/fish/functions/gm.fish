function gm -d "Checkout master and delete landed branches" 
    git checkout master
    arc queue-cleanup
end

