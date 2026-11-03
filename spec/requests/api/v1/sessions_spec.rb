require "rails_helper"

RSpec.describe "Authentication API", type: :request do
  let!(:user) do
    User.create!(
      email: "hr@acme.com",
      password: "securepassword123",
      first_name: "Jane",
      last_name: "Doe",
      role: "hr_manager"
    )
  end

  describe "POST /api/v1/session" do
    it "logs in successfully with valid credentials and sets session cookie" do
      post "/api/v1/session", params: { email: "hr@acme.com", password: "securepassword123" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["user"]["email"]).to eq("hr@acme.com")
      expect(json["user"]["first_name"]).to eq("Jane")
      expect(json["csrf_token"]).to be_present
      expect(session[:user_id]).to eq(user.id)
    end

    it "rejects invalid credentials with 401 Unauthorized" do
      post "/api/v1/session", params: { email: "hr@acme.com", password: "wrongpassword" }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Invalid email or password")
      expect(session[:user_id]).to be_nil
    end
  end

  describe "GET /api/v1/session" do
    it "returns current user data when authenticated" do
      post "/api/v1/session", params: { email: "hr@acme.com", password: "securepassword123" }
      get "/api/v1/session"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["user"]["email"]).to eq("hr@acme.com")
    end

    it "returns 401 when not authenticated" do
      get "/api/v1/session"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/session" do
    it "clears the session on logout" do
      post "/api/v1/session", params: { email: "hr@acme.com", password: "securepassword123" }
      expect(session[:user_id]).to eq(user.id)

      delete "/api/v1/session"
      expect(response).to have_http_status(:no_content)
      expect(session[:user_id]).to be_nil
    end
  end
end
