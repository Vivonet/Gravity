#Gravity
A simple XML-based layout description language for iOS powered by Auto Layout.

**tl;dr** It's kinda like HTML and is *infinitely* easier to use than Auto Layout.

##Sample
Here's what some actual functioning Gravity looks like:

```xml
<H gravity="middle" color="#fff">
	<V gravity="top left">
		<UILabel id="titleLabel" text="1188 W Georgia St" maxWidth="250" font="System Semibold 16" textColor="#ffffff" wrap="true"/>
		<UILabel id="hoursLabel" text="Open today: 6am - 11pm" font="System 14.0" textColor="#ffffff7f"/>
		<UIView height="6"/>
		<H gravity="middle" spacing="0" height="28" color="#ffffff">
			<UIButton id="carButton" backgroundColor="#0076FF" minWidth="80">
				<H alignment="center" userInteractionEnabled="false">
					<UIView width="4"/>
					<UIImageView width="22" height="22" image="Directions-Car"/>
					<UIView width="2"/>
					<UILabel text="12 mins" font="System Bold 16.0"/>
					<UIView width="4"/>
				</H>
			</UIButton>
			<UIView width="6"/>
			<UIButton id="walkButton" backgroundColor="#0076FF">
				<H alignment="center" userInteractionEnabled="false">
					<UIView width="4"/>
					<UIImageView width="22" height="22" image="Directions-Walk"/>
					<UIView width="2"/>
					<UILabel text="22 mins" font="System Bold 16.0"/>
					<UIView width="4"/>
				</H>
			</UIButton>
		</H>
	</V>
	<UIView width="8"/>
	<UIView>
		<UIButton width="64" backgroundColor="#ffffff00">
			<V alignment="center">
				<UIImageView image="chevron-right-bold"/>
				<UILabel text="Order" color="#fff"/>
			</V>
		</UIButton>
	</UIView>
</H>
```

##Introduction
In my thirty-five years of existence in this universe, I have encountered few things as brutally frustrating as Apple's Auto Layout engine. For a company that prides itself in the intuitiveness and ease of use of their software, Auto Layout represents a complete 180° on that stance, instead favouring bizarre and unnatural complexity over simplicity of design. The result is a beast of a system that takes many long hours to become even remotely proficient in.

Auto Layout has its apologists, and while there's no arguing it's a powerful system, the fact remains that if you've ever had to work with Auto Layout at some point in your career, you're all but guaranteed to have had a frustrating experience.

Auto layout tends to work well in two scenarios:

1. Extremely simple layouts, and
2. Extremely complex layouts.

It fails though, utterly in my opinion, at handling 99% of the layouts typical in modern software: those that need slightly more power than the absolute basic defaults, but which are not so mind-numbingly complex as to require the type of prioritized constraint engine Auto Layout is based upon (especially when 99% of its use is to resize a view from one screen size to a subtly different screen size).

Here's my background: I've always been a Mac guy, but I dabbled with .NET for a while in the mid 2000's. During this time I discovered (and eventually fell quite in love with) WPF, a.k.a. Windows Presentation Foundation. WPF represented a quantum leap forward in the natural expressibility of visual layouts using a simple hierarchical structure it called XAML.

After leaving the Windows world and coming back to Apple by means of the iOS platform, I was utterly dismayed at the mediocre layout tools available to me: at first it was Interface Builder with springs and struts. While the springs and struts model was a breeze to understand and worked fairly well for very simple interfaces, it was ultimately very limited in what it could express. But it wasn't until Apple released their "next big thing" in layout that things got truly bad.

"Auto Layout," they called it, as if it were some tongue-in-cheek sarcastic jab. Truly there is nothing automatic about it at all. It is in fact painstakingly manual. Now, instead of simply telling the computer which edges of an element should flow and which should be fixed in place, you have to tie individual edges of elements to each other, and chain these bindings together in precisely the right arrangement, for fear of not supplying all the required constraints, or supplying too many and having an ambiguous or conflicting constraint, all the while having many more things to have to worry about: (constraint priorities, content-hugging, collapse resistance, user-constraints, system-constraints, implicitly generated constraints, placeholder constraints, etc. etc.). Things went from simple but limited to insanely complex overnight.

Anyway if you've made it this far I'm probably preaching to the choir.

I hate Auto Layout. It is an utter failure on Apple's part to pave the way forward for developers and designers who want to spend their time building useful software that looks good and works well. Apple had a chance to really innovate in this area like they so often do in other areas, but instead sent the whole industry a huge leap backwards. This was especially unforgivable to me, who had spent the prior five years experiencing the joys of what interface layout could be (WPF wasn't perfect, don't get me wrong, but what it got right far and away made up for its shortcomings). Here I was going from an engine based on the principles of containment, reusability, object-orientedness, precision and determinism--the things we developers love--to this spaghetti pile of puke known as Auto Layout, where moving one thing in a UI could cause a chain reaction of broken layout constraints that leads to hours of retweaking to get your layout perfect again.

The *good* news is that Auto Layout is now sufficiently powerful enough to act as the foundation for another much-simpler layer built on top of it. Enter: Gravity.

Why "Gravity"?

Well, gravity is simple. It's a law: things attract. Gravity is the universe's way of optimizing space, just like your interface elements will automatically size and shrink to their ideal size and will just automatically look good and behave like you want.

Go ahead, sketch out a simple UI on a piece of paper or your favourite app. Looking at it, you already have a good idea of which elements should expand or shrink, and which elements should collapse before other elements. It's usually pretty obvious. Gravity aims to turn that intuitive knowledge into a functioning UI with as little work as possible.

Gravity is inspired on the surface by WPF, but is a much much simpler take on it. You define an interface as a tree: everything has its place in the hierarchy and the resultant interface is generated programmatically with all of the proper layout constraints in place, so you get all the power of auto layout without having to touch it.

Gravity is really a layout engine for programmers who prefer the precision and control of a code file. Unlike Interface Builder, which presents you with a visualization of your software and requires you to build and tweak that interface graphically, Gravity lets you tweak your interface *textually*, just like editing a code file. Yeah you have to rebuild and run to see your changes, but the control and precision it gives you is worth it. It's also far, far harder to accidentally do something you have no idea what and end up breaking your entire UI. Interface builder is fragile like that. Gravity is solid foundation.

Gravity is more than a layout engine. Gravity is a metaphor. For the way we picture and convey the information we want to display to our users. It is minimalism and efficiency.

Calling Gravity an "engine" is a bit of a stretch. Auto Layout is still the true engine powering Gravity. Gravity just gives you a much simpler way to specify your interface, and Auto Layout takes care of the real work behind the scenes. It's really just an interpretive layer that converts a simple XML document into a fully-constructed interface. Gravity is the curtain that hides the great and powerful Oz.

Coming soon.

##Q&A
**Q: Isn't a XIB file already XML? Why do I need another XML format?**
**A:** The answer has to do with the intended purpose of the XML and how it is utilized. Yes, XIB files are XML-based, but they're XML-based as a *serialization format*, not as a language with a user experience. XIB files are not intended to be authored by hand. Gravity, on the other hand, is designed from the ground up to be written by hand and is therefore intentionally simple and concise. Furthermore, XIB's XML format does absolutely nothing to abstract away the pains of Auto Layout. So even if you were to attempt to author a XIB file by hand (seriously though, don't), you'd still be programming with Auto Layout, albeit in a different form. Gravity is an abstraction layer built on top of Auto Layout. XIB is just Interface Builder serialized to XML.

**Q: Is there design-time support for Gravity?**
**A:** Not yet, but this is definitely something I would like to do. I am not sure what is possible and what not at this point. Please contribute if you have any ideas.

##Requirements
Gravity makes heavy use of the `UIStackView`, so iOS 9 only, I'm afraid! This is brand spankin' new stuff!