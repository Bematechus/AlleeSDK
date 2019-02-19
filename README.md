# AlleeSDK
AlleeSDK connects via TCP-IP communication point of sales software to kitchenGo allee software.  
This SDK works for IOS platform only.

You can see the [sample project here](https://github.com/Bematechus/AlleeSDKSample)
## Installation
### Cocoapods
AlleeSDK can be added to your project using [CocoaPods](https://cocoapods.org) by adding the following line to your `Podfile`:

    pod 'AlleeSDK'

### Submodule
Otherwise, AlleeSDK can be added as a submodule:
1. Add AlleeSDK as a submodule by opening the terminal, `cd`-ing into your top-level project directory, and entering the command `git submodule add https://github.com/Bematechus/AlleeSDK`
2. In the terminal `cd`-ing AlleeSDK folder, and entering the command `git submodule update --init --recursive`
3. Open the AlleeSDK folder, and drag AlleeSDK.xcodeproj into the file navigator of your app project.
4. In Xcode, navigate to the target configuration window by clicking on the blue project icon, and selecting the application target under the "Targets" heading in the sidebar.
5. Ensure that the deployment target of AlleeSDK.framework matches that of the application target.
6. In the tab bar at the top of that window, open the "General" panel.
7. Expand the "Embedded Binaries" group, and add AlleeSDK.framework.
8. In "Embedded Binaries" click on the + button, then "Add Other...", navigate to "AlleeSDK/Frameworks", and add BSocketHelper.framework.


## Usage
### Basic
To start use our AlleeSDK you need start it in your AppDelegate. I will need a STORE_KEY to do that:

    func application(_ application: UIApplication, 
            didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        ...
        AlleeSDK.shared.start(withStoreKey: "STORE_KEY")
        ...
        
        return true
    }
    

Allee orders are made with one `AlleeOrder` with any `AlleeItem` with any `AlleeCondiment`.  
So first we need create the condiments:

    let condiment = AlleeCondiment()
    condiment.id = UUID().uuidString
    condiment.name = "Tomatoes"
        
Then we can to create our items, inserting our condiments:

    let item = AlleeItem()
    item.id = UUID().uuidString
    item.name = "Veggie Burger"
    item.kDSStation = "1" // Target KDS preparation station
    item.quantity = 3
    item.condiments = condiments
    
    
We can also add a item recipe using `AlleeItemRecipe`: 

    let recipe = AlleeItemRecipe()
    recipe.image = "https://bit.ly/2I9dkxH"
    recipe.ingredients = ["1/2 medium yellow onion, chopped", "3/4 c. panko bread crumbs", "1 tomato, sliced"]
    recipe.steps = ["In a food processor, pulse black beans, onion, and garlic until finely chopped.",
                    "Transfer to a large bowl and combine with egg, 2 tablespoons mayo, and panko.",
                    "In a large skillet over medium heat, heat oil.", 
                    "Add patties and cook until golden and warmed through, about 5 minutes per side."]
                    
    item.itemRecipe = recipe
        
        
And to create our order, using the created items:

    let order = AlleeOrder()
    order.id = "1"
    order.items = items
        

We can also add a customer to order, using `AlleeCustomer`. **All customer data will be encrypted**:

    let customer = AlleeCustomer()
    customer.id = UUID().uuidString
    customer.name = "NAME"
    customer.phone = "PHONE"

    order.customer = customer
    
        
Now we need send this order to KDS, to do that we will use the `AlleeSDK.shared`:

    AlleeSDK.shared.send(order: order) { (error) in
        if let error = error {
            print(error)

        } else {
            print("Order sent")
        }
    }
        

### Orders preparation status
The AlleeSDK provides an observer for your POS to receive the orders status.  It is triggered automatically when some order status is changed, but you can also request manually if you need.

Set the delegate (**OrdersBumpStatusDelegate**) before the start:

    AlleeSDK.shared.ordersBumpStatusDelegate = self

And implement the method:

    func updated(ordersBumpStatus: [AlleeOrderBumpStatus]) {

    }
    
If you need you can request the orders status manually (Optional):

    AlleeSDK.shared.requestOrdersStatus { (error) in
        if let error = error {
            print(error)
        }
    }
    
**Note**: Only the new orders status is received.  
  
### Full Models
Still, if you need to provide more information in your order, please check all our orders data:

#### AlleeOrder

    var id: String? // Order ID
    var posTerminal: Int // POS Terminal ID
    var guestTable: String? // Table name
    var serverName: String? // Server Name
    var destination: String? // Destination (per exemple: Drive Thru, Diner, Delivery)
    var userInfo: String? // Another information about customer
    var orderMessages: [String]? // Custom messages
    var transType: AlleeTransType = .insert // Type of transaction (insert, delete, update)
    var orderType: OrderType = .regular // Order priority (regular, fire, rush)
    var items: [AlleeItem]? // Order items
    var customer: AlleeCustomer? // Order customer
    
    
#### AlleeItem

    var id: String? // Item ID
    var name: String? // Item Name
    var buildCard: String? // A text or a link with steps to prepare the item
    var trainingVideo: String? // A video link with steps to prepare the item
    var preModifier: [String]? // Item custom messages
    var preparationTime: NSNumber // How long time to prepare this item (in minutes)
    var quantity: Int = 1 // Item quantity
    var kDSStation: String? // Target KDS preparation station
    var transType: AlleeTransType = .insert // Type of transaction (insert, delete, update)
    var condiments: [AlleeCondiment]? // Item condiments
    var summary: AlleeSummary? // Summary of this item
    var itemRecipe: AlleeItemRecipe? // Recipe of this item
    var itemType: ItemType = .regular // Item priority (regular, fire)
    
    
#### AlleeCondiment

    var id: String? // Condiment ID
    var name: String? // Condiment Name
    var preModifier: [String]? // Condiment custom messages
    var transType: AlleeTransType = .insert // Type of transaction (insert, delete, update)
    var preparationTime: NSNumber // How long time to prepare this condiment (in minutes)
    
    
#### AlleeCustomer

    var id: String? // Customer ID
    var name: String? // Customer name
    var phone: String? // Customer phone
    var phone2: String? // Customer phone2
    var address: String? // Customer address
    var address2: String? // Customer address2
    var city: String? // Customer City
    var state: String? // Customer state
    var zip: String? // Customer zip code
    var country: String? // Customer country
    var email: String? // Customer E-mail
    var webmail: String? // Customer webmail 
    var transType: AlleeTransType = .insert // Type of transaction (insert, delete, update)
    
        
#### AlleeSummary

    var ingredientName: String? // Ingredient name
    var ingredientQuantity: Int = 1 // Quantity of this ingredient
    

#### AlleeItemRecipe

    var image: String? // Image URL
    var ingredients: [String]? // List of ingredients
    var steps: [String]? // List of steps
    var transType: AlleeTransType = .insert // Type of transaction (insert, delete, update)

