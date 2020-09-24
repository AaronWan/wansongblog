---
title: 第三章 ionic 实例 Trendicity
layout: detail
description: ionic 实例 Trendicity
category: [扩展知识,读书学习]
tags: [ionic,angularjs]
---

现在在你的工具箱中有很多工具，让我们来谈谈开发一个真正的手机应用。Instagram是一个非常受欢迎的照片分享应用。使这些照片更加有趣并且展示一些Ionic功能，我们将会涉及到一个我们开发应用，它叫 Trendicity。这个应用以多种方式获取和展示Instagram的照片。
    
一种方式就是根据照片的位置在地图上进行展示。另一种方式就是将照片展示在可以滑动的卡片上，并且用户可以标示出喜欢的照片。最后一种方式，我们以列表的形式展示照片和更多有关照片信息。
    
这个完整的[Trendicity](https://github.com/trendicity/trendicity)应用可以在Github上找到。你可以下载它并在你的浏览器或者设备或仿真器上运行。
    
Trendicity应用是作为一个side menu 应用建成的，可是，它也很好的结合了tabs方式。我们将会从几方面去讨论这个应用。Side Menu和用户的操作选项，搜索功能，和加载服务的使用和（地图示图，卡片视图和列表视图）tabs。
    
我们通过构建这个应用来深入了解代码。
    

##Side menu
    
侧边菜单由以下菜单项构成：

- HOME
- Favorites
- About
- Login/Logout

下面是Trendicity侧边菜单的截图。关于怎么样实现侧边菜单和路由时一直带着它的细节，请看第四章：实现侧边菜单和配置路由。

![侧边菜单](/images/ionic/side_menu.png)


##Home

HOME菜单选项点击时会调用HomtCtrl和展示地图Tab。地图上将会展示附近的一些图片。

![侧边菜单](/images/ionic/photo_on_map.png)

##Favorites

大体上，Trendicity应用的收藏功的实现有三部分组成：`FavoritesService`,`FavoritesCtrl`和`favorites.html`模版。

收藏功能有两种类型的照片会进行收存放：用户生成的和自己收藏的。前者是通过add-favorite模态窗口添加的，后者是通过地址位置直接关联到Instagram相片的。

这一部分，我们将会实际操作创建和删除收藏，看一下收藏功能是如何实现及`FavoritesCtrl`和`FavoritesServices`之间是如何交互的。

###收藏列表

收藏数据在一个列表中展现。当用户进入这个视图，会触发`$ionicView.enter`事件，这个视图中的数据将自动刷新：

```
$scope.$on('$ionicView.enter',function(){
   // Update favorites
   $scope.favorites = FavoritesService.getFavorites();
});
```
    
列表中的每一条收藏条目点击时都会在此相片的地理位置为中心定位到地图上。下面是收藏视图中展示收藏数据的代码：

```
<ion-list>
  <ion-item class="item-icon-right"
    ng-repeat="favorite in favorites track by favorite.id" ui-sref="app.home.map({ latitude: favorite.lat, longitude: favorite.lng })">
    \{\{ favorite.city \}\}
        <i class="icon ion-ios-arrow-forward icon-accessory"></i>
        <ion-option-button class="button-assertive" ng-click="deleteFavorite(favorite)">
          Remove
        </ion-option-button>
      </ion-item>
</ion-list>  
```

![收藏列表](/images/ionic/favorites_list.png)

添加一些友好的提示信息，当没有收藏信息要展示时，做如下操作：

```
  <!-- Display message when no favorites exist -->
    <div class="vertical-center-container" ng-show="!favorites.length">
      <div class="vertical-center text-center">
        <h1><i class="icon ion-heart-broken assertive"></i></h1>
        <p>Looks like you haven't favorited anything yet...</p>
      </div>
    </div>

```

![收藏列表](/images/ionic/no_favorited.png)

###添加收藏

为了保持代码的可维护性，我们决定将开发添加收藏功能的的代码进行解藕合。因此，我们将它拆分成了 FavoritesCtrl,FavoritesService,add-favorite.html模版，和add-favorite-form指令，让它们组合到一起完成这个功能。


添加收藏的动作，从点击右上角的'+'号打开一个添加收藏的模态窗口。

```
 <ion-nav-buttons side="right">
      <button class="button button-icon ion-ios-plus-empty" ng-click="showModalAddFavorite()"></button>
 </ion-nav-buttons>
```

点击这个按钮会触发FavoriteCtrl的showModalAddFavorite()方法，它会打开添加收藏的模态窗口。

```
$scope.showModalAddFavorite = function(){
    $scope.modalAddFavorite.show();
}
```

模态窗口中的内容都是有add-favorite-form指令负责生成。

```
<ion-content>
  <add-favorite-form on-submit="addFavorite(favorite)"></add-favorite-form>
</ion-content>
```
![添加收藏](/images/ionic/add_favorite.png =300x)


addFavoriteForm指令会在其内部处理onSubmit。当这个表单填写的没有问题提交时，会调用addFavoriteForm中的submit方法。也就是说，一旦表单没有问题，指令会调用submit方法，通过调用他的on-submit属性。

现在，指今如何知道去哪里找到addFavorite(favorite)方法呢？
当我们初始化模态时，会将FavoriteCtrl的作用域一并传入。因此，这个模态的作用域是继承自它的父作用域（即收藏视图的作用域）；

```
 $ionicModal.fromTemplateUrl('templates/modals/add-favorite.html', {
    scope: $scope
  }).then(function(modal) {
    $scope.modalAddFavorite = modal;
  });

```

这样，addFavorite()方法已经与控制器的作用域相关联：

```
  // Add a new favorite using the service
  $scope.addFavorite = function(favorite) {
    FavoritesService.add(favorite).then(function () {
      $scope.favorites = FavoritesService.getFavorites();
      $scope.hideModalAddFavorite();
    });
  };
```

当调用FavoritesService's add()方法后，将会更新收藏列表并具隐藏add-favorite模态。

###添加收藏表单指令

addFavoriteForm指令使用templates/directives/add-favorite-form.html作为它的模版。这个视图包含了表单的基础验证：

```
<form name="formAddFavorite" no-validate>
  <label class="item item-input item-stacked-label" ng-class="{ 'item-error': formAddFavorite.$attempt && formAddFavorite.city.$invalid, 'item-valid': formAddFavorite.city.$valid }">
    <span class="input-label">City</span>
    <input type="text" name="city" ng-model="favorite.city" placeholder="Dallas" required="required">
  </label>
  <label class="item item-input item-stacked-label" ng-class="{ 'item-error': formAddFavorite.$attempt && formAddFavorite.region.$invalid, 'item-valid': formAddFavorite.region.$valid }">
    <span class="input-label">State or Country</span>
    <input type="text" name="region" ng-model="favorite.region" placeholder="TX" required="required">
  </label>
  <button class="button button-full button-positive" type="button" ng-click="submit()">Add</button>
</form>
```

"Add"按钮会调用命令的submit()方法，会添加一个$attempt字段到表单中，标示用户已经最近已经提交了一次这个表单。这个字段被用来高亮不合法和没有输入的输入选项。

![有问题的表单](/images/ionic/invalid_form.png)

最后，当这个表单验证通过后，指令会通过模态中的一个属性调用onSubmit()方法：

```
 $scope.submit = function() {
        $scope.formAddFavorite.$attempt = true;

        if ($scope.formAddFavorite.$valid) {
          $scope.onSubmit({ favorite: $scope.favorite });
        }
      };
```

![合法的表单](/images/ionic/valid_form.png =300x)

而且，在这个模态关闭时，其中添加收藏的表单会自动清空。它是通过监听modal.hidden事件来进行实现的：

```
 $scope.$on('modal.hidden', function() {
        // Clear form
        $scope.favorite = null;
        $scope.formAddFavorite.$attempt = false;
        $scope.formAddFavorite.$setPristine(true);
      });
```

###删除收藏

当你滑动收藏条目时就可以进行删除收藏操作。

![删除收藏](/images/ionic/remove_operate.png =300x)

点击删除按钮，将会调用FavoritesCtrl的deleteFavorite()方法删除当前收藏的引用。在控制器这边，这个方法会调用FavoritesService的delete方法，将收藏列表中的当前操作的收藏项删除。

```
  // Delete a favorite using the service and update scope var
  $scope.deleteFavorite = function (favorite) {
    $scope.favorites = FavoritesService.delete(favorite);
  };

```

###收藏服务

FavoritesService是用标准方式来处理Trendicity中与收藏相关的服务。它将收藏相关逻辑与Trendicity其它功能隔离开。用这种方式的另一个好处就是FavoritesService服务可以在任何一个 Controller中使用。像我们在列表视图中实现的那样,这个服务被用来收藏自己喜欢的地理位置。

这个服务提供了三个方法：add(),getFavorites()和delete()

正如它们的名字叫的那样，getFavorites()会直接返回当前本地的所有收藏。

添加收藏时的处理方式根据收藏的类型而定。对于人们经常收藏的城市或区域，这个类型的收藏会用GeolocationService的addressToPosition()方法获取地理坐标。这个实现我们在稍后章节中会进行讨论。当获取到了地址经纬度，这个收藏会统一格式化一种结构存储到本地的收藏数组中。

```
  var address = favorite.city + ', ' + favorite.region;
      return GeolocationService.addressToPosition(address).then(function (data) {
        var newLocation = {
          id: favoritesId,
          city: address,
          lat: data.latitude,
          lng: data.longitude
        };
        favorites.push(newLocation);
        localStorageService.set('Favorites', favorites);
      });

```

针对具体的收藏，收藏会在列表视图的控制器中进行合适的格式化处理，和用户添加的收藏的处理过程相信，存放到本地收藏数据中。

```
  var newLocation = {
     id: favoritesId,
     city: address,
     lat: data.latitude,
     lng: data.longitude
  };
  favorites.push(newLocation);
  localStorageService.set('Favorites', favorites);
```

为了确保准确定位，这个服务为第一个收藏生成了一个对应的ID。每一个id都是根据当前系统的时间生成的：

```
 this.add = function (favorite) {
    var favorites = this.getFavorites() || [];
    var favoritesId =  new Date().getTime();
 ...
 };

```

删除收藏的工作通过使用lodash的remove()方法实现。删除了收藏后，更新本地收藏并将最新的收藏列表返回。

```
  // DELETE
  this.delete = function (favorite) {
    var favorites = this.getFavorites();
    _.remove(favorites, favorite); // jshint ignore:line
    localStorageService.set('Favorites', favorites);
    return this.getFavorites();
  };
```

##About

‘About’菜单选项点击时会滑出界面，包含一些应用的介绍信息。这个页面会在应用程序第一次加载时显示。

![](/images/ionic/about_1.png)

![](/images/ionic/about_2.png)

![](/images/ionic/about_3.png)

##Login/Logout

当用户还没有登陆要登陆时，点击菜单的'Login'时会显示登陆界面。一旦用户登陆后，再点开菜单，'Logout'选项将出展示。

下面是www/templates/menu.html部分代码片断，展示了如何用ng-show和ng-hide实现上述功能。

```
<ion-item menu-close class="item-icon-left" ng-click="login()" ng-hide="isLoggedIn()">
    <i class="icon ion-log-in"></i>
    Login
</ion-item>
<ion-item menu-close class="item-icon-left" ng-click="logout()" ng-show="isLoggedIn()">
    <i class="icon ion-log-out"></i>
    Logout
</ion-item>
```

你可以在www/controllers/app.js文件中找到isLoggedIn,login和logout方法：

```
  // Determine if the user is logged into Instagram
  $scope.isLoggedIn = function() {
    return InstagramService.isLoggedIn();
  };

  // Open the login modal
  $scope.login = function() {
    $scope.loginModal.show();
  };

  // Perform the logout action when the user invokes the logout link
  $scope.logout = function() {
    InstagramService.logout();
  };

```

isLoggedIn方法会调用InstagramService的isLoggedIn()方法来获取当前登陆状态。退出方法会调用InstagramService的logout()方法来进行登记退出动作。我们会在第八章讲解更多关于InstagramService相关的内容。

为了做更多和Instagram相关并有趣的事情，我们需要用户登陆到Instagram。为了实现这个，我们使用一个$ionicModal显示为什么让用户登陆的简要的描述。当选择了登陆选项，login方法被调用，用户会看到一个登陆模态。

![登陆截图](/images/ionic/login.png =300x)

```javascript
  // Create the login modal that we will use later
  $ionicModal.fromTemplateUrl('templates/modals/login.html', {
    scope: $scope,
    animation: 'slide-in-up'
  }).then(function(modal) {
    $scope.loginModal = modal;
  });

  // Triggered in the login modal to close it
  $scope.closeLogin = function() {
    InstagramService.loginCancelled();
    $scope.loginModal.hide();
  };

  //Cleanup the modal when we're done with it!
  $scope.$on('$destroy', function() {
    $scope.loginModal.remove();
  });

```

通常，登陆页面像下面截图中展示一样。但是由于我们要与Instagram集成，我们需要OAuth的方式进行登陆。

![登陆截图](/images/ionic/normal_login.png)

```
<ion-modal-view id="login">
  <ion-header-bar class="bar-transparent">
    <div class="buttons">
      <button class="button button-light button-clear button-icon button-right icon ion-close" ng-click="closeLogin()"></button>
    </div>
  </ion-header-bar>
  <ion-content scroll="false">
      <div class="vertical-center-container">
        <div class="vertical-center">
          <div class="row light-bg">
            <div class="col">
              <h3 class="text-center">Login with Instagram to</h3>
              <ul class="text-center">
                <li><i class="icon ion-heart assertive"></i> Like Posts</li>
                <li><i class="icon ion-images"></i> View Your Feed</li>
                <li><i class="icon ion-star energized"></i> View Your Liked Posts</li>
              </ul>
              <button class="button button-block button-positive button-outline icon-left ion-social-instagram-outline" ng-click="loginToInstagram()">Login with Instagram</button>
            </div>
          </div>
        </div>
      </div>
  </ion-content>
</ion-modal-view>
```

用Oauth代替传统的登陆方式，让用户知道一旦登陆到了Instagram,他们能做哪些事情。一旦用户确定登陆到Instagram,我们会调用www/controllers/app.js中的loginToInstagram方法：

```
  // Perform the OAuth login to Instagram
  $scope.loginToInstagram = function() {
    $scope.loginModal.hide();
    InstagramService.login();
  };
```

这个方法将会用InAppBrowser Cordova插件执行OAuth授权。我们会使用这个插件打开一个登陆到Instagram窗口。Trendicity应用没有对用户名和密码进行处理。

![Instagram登陆](/images/ionic/instagram_login.png =300x)

##Search

搜索图标就是在列表或卡片视图的右上角的放大镜图标。用户有以下查询选项：

- Trending - 按当前在Instagram上帖子的受欢迎程序进行排序。
- Nearby - 当前用户所在位置1KM范围内发布的帖子。
- My Feed - 当前用户提供给Instagram的信息。
- My Liked Posts -当前用户喜欢的帖子。

![search](/images/ionic/search.png =300x)

在HomeCtrl中，我们设置了查询功能。为了关注搜索功能，下面代码进行稍微的压缩。

首先，我们定义了一些作用域变量来保存帖子和查询变量。我们使用了两个javascript对象来存放，所以当值发生变化时，对象不会丢失。
 
 ```
 $scope.model = PostsService.getModel();
 $scope.search = {value:POST_TYPE.NEARBY};
 ```
 
 接下来，我们设置$scope.getPosts方法，它将会根据查询值决定哪些查询方法会被调用。
 
 ```
     $scope.getPosts = function(value) {
       if (value === POST_TYPE.TRENDING) {
         PostsService.findPopularPosts();
       } else if (value === POST_TYPE.NEARBY) {
         $scope.findNearbyPosts();
       } else if (value === POST_TYPE.USER_FEED) {
         PostsService.findUserFeedPosts();
       } else if (value === POST_TYPE.LIKED) {
         PostsService.findLikedPosts();
       }
     };
 ```
 
 通过$watch监听ionicPopover中查询变量值的变化来及时调用$scope.getPosts方法来进行查询。
 ```
     $scope.updatePosts = function (searchValue) {
       $scope.getPosts(searchValue);
       $scope.closePopover();
       $ionicScrollDelegate.scrollTop();
     };
     
     $scope.$watch('search.value', function(newValue) {
         // Triggered when user changes search value
         $scope.updatePosts(newValue);
     });
 
 ```
 
 
为了实现ionicPopover,我们首先需要通过 fromTemplateUrl 方法加载 html 模版。我们在这里将其作用域设置为当前作用域。当template加载时，我们将popover设置到这个作用域中，方便我们后面进行调用。

```
    $ionicPopover.fromTemplateUrl('templates/search.html', {
      scope: $scope,
    }).then(function(popover) {
      $scope.popover = popover;
    });

```

下面这段 search.html 模版片段。我们使用了ion-popover-view 组件定义这个视图。我们使用 ion-header-bar 组件展示弹出窗口的标题。我们将 ion-radio 组件列表放到 ion-content 组件中。ion-radio组件选择后，会作为搜索参考值。


```
<ion-popover-view>
    <ion-header-bar>
        <h1 class="title">Search</h1>
    </ion-header-bar>
    <ion-content>
        <ion-radio ng-model="search.value" value="TR">Trending</ion-radio>
        <ion-radio ng-model="search.value" value="NB">Nearby</ion-radio>
        <ion-radio ng-model="search.value" value="UF">My Feed</ion-radio>
        <ion-radio ng-model="search.value" value="LP">My Liked Posts</ion-radio>
    </ion-content>
</ion-popover-view>
```

当用户点击在templates/home.html中定义的导航按钮时 这个 ionicPopover 将会弹出。下面地这段代码：

```
      <ion-nav-buttons side="right">
          <button class="button button-icon icon ion-ios-search" ng-click="openPopover($event)"></button>
      </ion-nav-buttons>
```

由上面代码可以看到，当用户点击Search图标时，会调用openPopover方法。我们要做的就是让popover显示。当选择了一个值时，将会调用closePopover方法，在这个方法中，我们要确认popover是已经定义并是打开的。如何条件满足，我们就将其关闭。最后一件事情就是为popover设置一个$destroy监听，当popover被从Dom中移除时调用。

```
 $scope.openPopover = function($event) {
      $scope.popover.show($event);
    };

    $scope.closePopover = function() {
      if ($scope.popover && $scope.popover.isShown()) {
        $scope.popover.hide();
      }
    };

    // Cleanup the popover when we're done with it!
    $scope.$on('$destroy', function() {
      if ($scope.popover) {
        $scope.popover.remove();
      }
    });

```


##加载服务

当照片进行加载时，用户会不知道应用在做什么，我们应该通知用户当前是在加载数据。我们可以使用$ionicLoading组件来完成这件事情。

![loading](/images/ionic/ionic_loading.png =300x)


一种聪明的方式就是将 $ionicLoading 组件调用用放在一个HTTP拦截器中。下面是我们压缩后的代码：

```

.factory('TrendicityInterceptor',
  function ($injector, $q) {
    var hideLoadingModalIfNecessary = function() {
      var $http = $http || $injector.get('$http');
      if ($http.pendingRequests.length === 0) {
        $injector.get('$ionicLoading').hide();
      }
    };

    return {
      request: function(config) {
        $injector.get('$ionicLoading').show();
       ...
      requestError: function(rejection) {
        hideLoadingModalIfNecessary();
        return $q.reject(rejection);
      },
      response: function(response) {
        hideLoadingModalIfNecessary();
        return response;
      },
      responseError: function(rejection) {
        hideLoadingModalIfNecessary();
        return $q.reject(rejection);
      }
    };
  }
);

```

当HTTP请求发生时，request方法将会被调用。这里我们显示文字 "Loading"。为了避免依赖死循环，我们需要用Angular $injector组件来获取$ionicLoading服务。

当HTTP请求出现错误时，这里会调用requestError方法。我们会调用hideLoadingModalIfNecesary()方法，这个方法会检查是否有HTTP请求在被调用，如果没有ionicLoading服务会将自己隐藏。

当HTTP响应成功时，会调用response方法。之后做的事情与错误时的处理方法类似。

当HTTP响应错误时，会调用responseError方法。之后做的事情与上面两种情况处理方法类似。

为了使我们的HTTP拦截器生效，我们需要让AngularJS知道它的存在。一般我们会在www/app.js中做这件事情。这里是我们将拦截器通过$httpProvider添加到拦截器数据中的方法：

```
.config(function($httpProvider) {
  $httpProvider.interceptors.push('TrendicityInterceptor');
})
```

注意，这里我们没有显示真正的提示信息，只是在www/app.js中设置了一个默认信息:

```
.constant('$ionicLoadingConfig', {
  template: '<ion-spinner></ion-spinner>Loading...'
})
```
我们在第七章会详细讲解：设计应用。现在，我们只是想告诉你为什么不向ionicLoading show方法中传入信息。

##Map视图选项

将当前提交的信息在一个可以交互的地图上展示。一个标记会将用户的位置标在地图上。别的照片按它的位置展现在地图上。当点击这个这个标记时，相关联的照片会展现出来。如果你移动地图到一个位置 ，然后点击右上角的刷新图标；就会加载当前位置周边的照片。若想了解如何实现的，请看第五章：在ionic上集成地图。

##Card实图选项

卡片视图将以卡片叠加的方式来展现照片。若用户不喜欢当前的照片，可以将图片向左侧拖拽或划动。如果喜欢的话可以向右侧拖拽或划动。

这些可以摆动的卡券与非常受欢迎的手机应用Tinder相似。这种类似的实用的功能在Tinder中经常会被用到。

Drify（该公司负责我们的ionic技术）创始人之一Max Lynch已经创建了一个划动卡片的库，这个库经常会被ionic开发团队引用。在ionic中这样的效果展示通常会比较受欢迎的。

这个类库用CSS的动画来实现卡片左右拖拽和摆动的效果。他也使用了一个物理样式动化效果库Collide来实现将图片下拉时的动画效果。

在使用Tinder卡片库之前，一个非常相似的卡片划动效果被创建。我们只是在这里提一下它，在你看到这块时不要好奇。我们在这里没有涉及到这个库。

###工作文件

与该视图相关的文件位置在：`www/templates/tab-card.html`,`www/templates/card-intro.html`,`www/js/controllers/card.js`和`www/js/directives/no-touch-move.js`。

###popup介绍

当导航到卡片实图时，我们决定弹出展示说明信息，来向用户介绍和让他们熟悉如何使用卡片的操作。

我们使用$ionicPopup服务来展示Ionic样式的弹出窗信息。这个服务允许你定义四种类型的弹出窗：

- show(选项) ：通过加载的选项设置来完全自定义弹出窗

- alert(选项) ：带有一个按钮的弹出窗

- confirm(选项)：带有确认信息和“取消”和“确认”铵钮的弹出窗

- prompt(选项)：和confirm一样，但是多出一个与用户交互的输入框。

为我们Trendicity应用，自定义了一个弹出窗如：

```
    // Show explanation message
    $ionicPopup.show({
      title: 'Swipe Cards',
      templateUrl: 'templates/popups/card-intro.html',
      scope: $scope,
      buttons: [
        {
          text: 'Next',
          type: 'button-positive',
          onTap: function(e) {
            if (slidebox.currentIndex() === 0) {
              // Go to next slide
              slidebox.next();

              // Change button text
              e.target.innerHTML = 'OK';

              e.preventDefault();
            } else {
              // Close popup
              return;
            }
          }
        }
      ]
    });

```

弹出窗的信息体部分通过template和templateUrl选项进行定义。我们这里单独定义这个模版文件：templates/card-intro.html

我们的模版文件中包含一个划动的盒子，可以流畅的在照片与照片之间进行划动。

```
<ion-slide-box does-continue="false" show-pager="false" delegate-handle="card-intro-slidebox" ng-init="disableSlideBox()">
    <ion-slide>
        <img class="full-image" src="img/swipe-right.png" />
    </ion-slide>
    <ion-slide>
        <img class="full-image" src="img/swipe-left.png" />
    </ion-slide>
</ion-slide-box>
```

这个盒子组件是由AngularJS服务$ionicSlideBoxDelegate生成。这个服务允许你控制这个组件的行为，如划动时的效果和控制是否自动播放。另外当再次渲染这个盒子时调用update()方法。


我们这里，禁止照片的自动切换和用户划动，而所有的操作只能通过铵钮来进行完成。
```
  // Disable intro slidebox sliding
    $scope.disableSlideBox = function() {
      $ionicSlideBoxDelegate.enableSlide(false);
    };
```

弹出窗口提供了一个回调onTap,这里可以让用户去自己做一些事情。如果当前是第一个照片，点击“Next"铵钮，我们通过调用$ionicSlideBoxDelegate.$getByHandle('card-intro-slidebox')实例的next()打开下一张照片,并且修改铵钮的文字为"OK"同时防止弹出窗口关闭。另外，当在最后一个照片时，我们会调用return并关闭弹出窗口。

最后，每次用户访问卡片视图时，我们会查看一下本地存储seenCardIntro的值来判断用户是否已经看这个卡片。

###Card视图

在www/templates/tab-card.html文件中，我们会展示卡片集合。我们通过ng-repeat来迭代显示照片。让后我们定义一些属性来响应用户对卡片的操作。

```
<ion-view title="Card View" cache-view="false" no-scroll>
    <ion-content class="has-header padding">
        <div ng-if="model.currentPosts.length">
            <td-cards>
                <td-card ng-repeat="post in model.currentPosts" on-destroy="cardDestroyed($index)"
                         on-transition-left="cardTransitionedLeft($index)"
                         on-transition-right="cardTransitionedRight($index)">
                    <div class="image">
                        <div class="no-text">NOPE</div>
                        <img ng-src="{{ post.images.low_resolution.url }}" />
                        <div class="yes-text">LIKE</div>
                    </div>
                </td-card>
            </td-cards>
        </div>
    </ion-content>
</ion-view>
```
###Card视图对应的controller

我们需要CardViewCtrl使侧边滑出菜单失效，因为它会与Tinder卡片功能冲突 。这里我们通过$ionicSidemenuDelegate来设置当内容进入视图时拖拽不可用。当离开视图时，我们恢复可用，使别的视图下可以打开侧边菜单。

```

.controller('CardViewCtrl', function (
  $scope,
  $ionicSideMenuDelegate,
  $ionicPopup,
  $ionicSlideBoxDelegate,
  $timeout,
  $ionicHistory,
  localStorageService,
  PostsService,
  InstagramService) {

  // Disable side-menu drag so that it doesnt interfere with our tinder cards functionality
  $scope.$on('$ionicView.enter', function() {
    $ionicHistory.clearHistory();
    $ionicSideMenuDelegate.canDragContent(false);
  });

  $scope.$on('$ionicView.leave', function() {
    $ionicSideMenuDelegate.canDragContent(true);
  });

  if (!localStorageService.get('seenCardIntro')) {
    // Mark intro as seen
    localStorageService.set('seenCardIntro', true);

    var slidebox = $ionicSlideBoxDelegate.$getByHandle('card-intro-slidebox');

    // Disable intro slidebox sliding
    $scope.disableSlideBox = function() {
      $ionicSlideBoxDelegate.enableSlide(false);
    };

    // Show explanation message
    $ionicPopup.show({
      title: 'Swipe Cards',
      templateUrl: 'templates/popups/card-intro.html',
      scope: $scope,
      buttons: [
        {
          text: 'Next',
          type: 'button-positive',
          onTap: function(e) {
            if (slidebox.currentIndex() === 0) {
              // Go to next slide
              slidebox.next();

              // Change button text
              e.target.innerHTML = 'OK';

              e.preventDefault();
            } else {
              // Close popup
              return;
            }
          }
        }
      ]
    });
  }

  $scope.cardTransitionedLeft = function(index) {
    console.log('cardTransitionedLeft called with index:' + index);
    if (!InstagramService.isLoggedIn()) {
      console.log('not sure if you liked it before or not since you are not logged in; doing nothing!');
      return;
    }

    var post = $scope.model.currentPosts[index];
    if (post.user_has_liked) { // jshint ignore:line
      PostsService.dislikePost(post.id)
        .success(function() {
          console.log('you disliked it!');
        });
    } else {
      console.log('you didnt like it in the first place!');
    }
  };

  $scope.cardTransitionedRight = function(index) {
    console.log('cardTransitionedRight called with index:' + index);
    if (!InstagramService.isLoggedIn()) {
      console.log('not sure if you liked it before or not since you are not logged in; if you login, we will like it for you');
    }

    var post = $scope.model.currentPosts[index];
    if (!post.user_has_liked) { // jshint ignore:line
      PostsService.likePost(post.id)
        .success(function () {
          console.log('you liked it!');
        });
    } else {
      console.log('you already liked it previously!');
    }
  };

  $scope.cardDestroyed = function(index) {
    console.log('cardDestroyed called with index:' + index);
    $scope.model.currentPosts.splice(index, 1);
  };

});
```
这里cardTransitionedLeft和cardTransitionRight 方法基本上一样的，除了，左滑进代表不喜欢，右滑是代表喜欢。两者都要判断是否已经登陆。如何用户喜欢当前的卡片但又没有登陆时，会要求用户登陆。一旦登陆成功，这个卡片就会被收藏。这是我们安全认证方案的结果。你可以通过第六章节的 验证 来了解更多的信息。

当一个卡片一旦过渡完并且被销毁时就会调用cardDestroyed方法。我们这里只是将卡片从照片数组中删除。

##List视图选项

Trendicity的列表选项是为了展示ionic核心的列表功能而开发的。比较受欢迎的组件为：拉取刷新，button bars action sheets,视图中的手势。这一部分我们将解析开发列表的过程，和上述的组件。

###涉及文件

列表视图功能涉及的文件：www/templates/tab-list.html,www/js/controllers/list.js和www/js/directives/on-dbl-top.js。路由在www/js/app.js中定义的：
 
```
.state('app.home.list',{
        url:'/list',
        views:{
            'tab-list':{
                templateUrl:'templates/tab-list.html',
                controller:'ListViewCtrl'
            }
        }
} 
```

###模板布局

列表视图模板可以被切分成三部分：刷新，帖子列表，和包含用户可操作铵钮的铵钮条。

###刷新帖子列表

Ionic提供了非常有用的指令，名字为ion-refresher。在使用这个组件时，将标签放到你的视图上，并添加在视图控制器中添加一个处理用户交互的方法，一旦用户向下拉取内容或者触发刷新机制。

![列表视图](/images/ionic/list_view.png =300x)

为了保存简单易用，我们选择一个刷新铵钮（ion-arrow-down-c）来代替默认的图标,同时设置下拉时提示的文字。

```
<ion-refresher pulling-icon="ion-ios-arrow-up" spinner="none" pulling-text="Pull to refresh..." on-refresh="doRefresh()"></ion-refresher>

```
注意：这个命令允许你通过下面属性来覆盖它默认的配置：

- on-refresh:一旦用户下拉放开后触发刷新机制。
- on-pulling:一旦用户开始下拉时调用。
- pulling-icon:当用户下拉时显示的图标。
- pulling-text:当用户下拉时显示的文本。
- refreshing-icon:当刷新机制一旦触发，这个图标就会显示。
- refreshing-text:一旦数据刷新后，显示的文本。
- disable-pulling-rotation:一旦on-refresh调用开始调用，停止旋转图标。

ionrefresher组件值得注意的提升就是，添加了一个定时器，当很快获取到数据时，刷新显示数据也要耗时最少要400ms。这种情况超时创造一个平滑过渡的假像，使用户感觉到数据是刷新了。

我们回到Trendicity,refresher设置当用户希望获取新的帖子时，触发控制器的doRefresh方法。下面就是刷新时调用的方法：

```
  // Refresh feed posts
  $scope.doRefresh = function() {
    $scope.getPosts($scope.search.value);

    // Hide ion-refresher
    $scope.$broadcast('scroll.refreshComplete');
  };
```
就像前面章节解释的那样，我们使用HomeCtrl的getPosts方式










































