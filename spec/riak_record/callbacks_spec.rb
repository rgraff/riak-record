require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class Example
  include RiakRecord::Callbacks
end

describe RiakRecord::Callbacks do

  let(:example_class) { Example }
  let(:example){ example_class.new }

  before :each do
    example_class.instance_variable_set("@_callbacks", nil)
    example_class.before_save("nil")
  end

  describe "adding call backs" do
    it "should add to the callbacks" do
      example_class.after_save(:a_new_callback)
      expect( example_class._callbacks(:after_save).last ).to eq(:a_new_callback)
    end

    it "should append to the callbacks" do
      example_class.append_before_save(:a_late_callback)
      expect( example_class._callbacks(:before_save).last ).to eq(:a_late_callback)
    end

    it "should prepend to the callbacks" do
      example_class.prepend_before_save(:an_early_callback)
      expect( example_class._callbacks(:before_save).first ).to eq(:an_early_callback)
    end
  end


  describe "call_callbacks!" do
    it "should call symbol callbacks" do
      example_class.before_save(:a_symbol_callback)
      expect( example ).to receive(:a_symbol_callback).and_return(nil)
      example.before_save!
    end

    it "should eval string callbacks" do
      class EvalProof < StandardError
      end
      example_class.before_save("raise EvalProof")
      expect{
        example.before_save!
      }.to raise_error(EvalProof)
    end

    it "should call CallbackObjects" do
      class CallbackObject
        def before_save
        end
      end
      callback_object = CallbackObject.new
      example_class.before_save(callback_object)
      expect(callback_object).to receive(:before_save)
      example.before_save!
    end

    it "should call procs" do
      a_proc = Proc.new{|a| a}
      example_class.before_create(a_proc)
      expect(a_proc).to receive(:call).with(example).and_return(nil)
      example.call_callbacks!(:before_create)
    end
  end

end
