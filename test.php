<!DOCTYPE html>
<html>
  <head>
    <title>iOS and Js</title>
    <style type="text/css">
      * {
        font-size: 40px;
      }
    </style>
  </head>

  <body>

    <div style="margin-top: 100px">
      <h1>Test how to use objective-c call js</h1><br/>
      <div><input type="button" value="call js alert" onclick="callJsAlert()"></div>
      <br/>
      <div><input type="button" value="Call js confirm" onclick="callJsConfirm()"></div><br/>
    </div>
    <br/>
    <div>
      <div><input type="button" value="Call Js prompt " onclick="callJsInput()"></div><br/>
      <div>Click me here: <a href="http://www.baidu.com">Jump to Baidu</a></div>
    </div>

    <br/>
    <div id="SwiftDiv">
      <span id="jsParamFuncSpan" style="color: red; font-size: 50px;"></span>
    </div>



    <script type="text/javascript">
      function callJsAlert() {
        alert('Objective-C call js to show alert');

<!--        window.webkit.messageHandlers.login.postMessage({body: 'call js alert in js'});-->


        // var cookie_val = getCookie("token");
        // alert(cookie_val);



        // var userCar = '<?php echo $_COOKIE["token"] ?>';
        // alert(userCar);

        window.webkit.messageHandlers.login.postMessage({});
      }


    function getCookie(cookie_name)

    {

        var allcookies = document.cookie;

        var cookie_pos = allcookies.indexOf(cookie_name);   //索引的长度



        // 如果找到了索引，就代表cookie存在，

        // 反之，就说明不存在。

        if (cookie_pos != -1)

        {

            // 把cookie_pos放在值的开始，只要给值加1即可。

            cookie_pos += cookie_name.length + 1;      //这里我自己试过，容易出问题，所以请大家参考的时候自己好好研究一下。。。

            var cookie_end = allcookies.indexOf(";", cookie_pos);



            if (cookie_end == -1)

            {

                cookie_end = allcookies.length;

            }



            var value = unescape(allcookies.substring(cookie_pos, cookie_end)); //这里就可以得到你想要的cookie的值了。。。

        }



        return value;

    }



    // 调用函数


    function callJsConfirm() {
      if (confirm('confirm', 'Objective-C call js to show confirm')) {
        document.getElementById('jsParamFuncSpan').innerHTML
        = 'true';
      } else {
        document.getElementById('jsParamFuncSpan').innerHTML
        = 'false';
      }

      // AppModel是我们所注入的对象
      window.webkit.messageHandlers.AppModel.postMessage({body: 'call js confirm in js'});
    }

    function callJsInput() {
      var response = prompt('Hello', 'Please input your name:');
      document.getElementById('jsParamFuncSpan').innerHTML = response;

       // AppModel是我们所注入的对象
      window.webkit.messageHandlers.AppModel.postMessage({body: response});
    }
      </script>

<div style="background: red">

      <?php

        echo "token:";
        echo $_COOKIE['token'];
        ?>




    </div>

  </body>
</html>
