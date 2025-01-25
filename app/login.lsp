<?lsp

local function trim(s) return s:gsub("^%s*(.-)%s*$", "%1") end

local username,password=app.getCredentials()
local data=request:data()
if "POST" == request:method() then
   if data.username and data.password then
      local u,p=trim(data.username),trim(data.password)
      if username then
	 if u==username and p==password then
	    tracep(10,"Login OK")
	    app.createLoginCookie(response)
	    response:sendredirect"./"
	 end
      else
	 app.saveCredentials(u,p)
	 response:sendredirect""
      end
   end
end

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Page</title>
    <style>
	body {
	    display: flex;
	    justify-content: center;
	    align-items: center;
	    height: 100vh;
	    margin: 0;
	    font-family: Arial, sans-serif;
	    background-color: #f5f5f5;
	}

	.container {
	    display: flex;
	    flex-direction: column;
	    align-items: center;
	    gap: 20px;
	    background-color: white;
	    padding: 40px;
	    border-radius: 10px;
	    box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
	}

	.title {
	    font-size: 24px;
	    font-weight: bold;
	    margin-bottom: 20px;
	}

	.input-group {
	    display: flex;
	    flex-direction: column;
	    gap: 10px;
	    width: 100%;
	}

	.input-group label {
	    font-size: 14px;
	    font-weight: bold;
	}

	.input-group input {
	    padding: 10px;
	    font-size: 14px;
	    border: 1px solid #ccc;
	    border-radius: 5px;
	    width: 100%;
	    box-sizing: border-box;
	}

	.button {
	    margin-top: 20px;
	    padding: 10px 20px;
	    font-size: 16px;
	    font-weight: bold;
	    color: white;
	    background-color: #007bff;
	    border: none;
	    border-radius: 5px;
	    cursor: pointer;
	    width: 100%;
	}

	.button:hover {
	    background-color: #0056b3;
	}
    </style>
</head>
<body>
    <div class="container">
	<div class="title"><?lsp=username and "Login" or "Create User"?></div>
	<form method="POST">
	    <div class="input-group">
		<label for="username">Username</label>
		<input type="text" id="username" name="username" placeholder="Enter your username" required>
	    </div>

	    <div class="input-group">
		<label for="password">Password</label>
		<input type="password" id="password" name="password" placeholder="Enter your password" required>
	    </div>

	    <button type="submit" class="button"><?lsp=username and "Login" or "Save"?></button>
	</form>
    </div>
</body>
</html>
